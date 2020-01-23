//
//  SLHEncoderItem.m
//  Slash
//
//  Created by Terminator on 2018/11/15.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import "SLHEncoderItem.h"
#import "SLHMediaItem.h"
#import "SLHMediaItemTrack.h"
#import "SLHEncoderItemOptions.h"
#import "SLHFilterOptions.h"
#import "SLHEncoderItemMetadata.h"

#import "MPVPlayerItem.h"
#import "MPVPlayerItemTrack.h"

@interface SLHEncoderItem ()

@property (nonatomic) double duration;
@property (nonatomic) uint64_t estimatedSize;

@end

@implementation SLHEncoderItem

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    SLHEncoderItem *item = [[self.class allocWithZone:zone] init];
    
    item->_playerItem = _playerItem;
    
    item->_outputPath = _outputPath.copy;
    item->_container = _container.copy;
    
    item->_interval = _interval;
    item->_videoStreamIndex = _videoStreamIndex;
    item->_audioStreamIndex = _audioStreamIndex;
    item->_subtitlesStreamIndex = _subtitlesStreamIndex;
    
    item.videoOptions = _videoOptions.copy;
    item.audioOptions = _audioOptions.copy;
    item->_filters = _filters.copy;
    
    item->_twoPassEncoding = _twoPassEncoding;
    
    item->_metadata = _metadata.copy;
    item->_tag = _tag;

    [item addObservers];
    
    return item;
}

#pragma mark - Initialize

- (instancetype)initWithPlayerItem:(MPVPlayerItem *)item outputPath:(NSString *)outputMediaPath {
    self = [super init];
    if (self) {
        _playerItem = item;
        _outputPath = outputMediaPath;
        _subtitlesStreamIndex = -1;
        _videoStreamIndex = -1;
        _audioStreamIndex = -1;
        _twoPassEncoding = NO;
        self.videoOptions = [SLHEncoderItemOptions new];
        self.audioOptions = [SLHEncoderItemOptions new];
        _filters = [SLHFilterOptions new];
        _filters.subtitlesStyle = @"FontName=Helvetica,FontSize=14,PrimaryColour=&H00000000,BackColour=&H40FFFFFF,BorderStyle=4,Shadow=2,Outline=0";
        _filters.additionalVideoFiltersString = @"";
        _filters.additionalAudioFiltersString = @"";
        _metadata = [[SLHEncoderItemMetadata alloc] initWithPlayerItem:item];
        
        [self addObservers];

    }
    return self;
}

- (void)addObservers {
    [self addObserver:self forKeyPath:@"intervalStart" options:NSKeyValueObservingOptionNew context:&SLHEncoderItemKVOContext];
    [self addObserver:self forKeyPath:@"intervalEnd" options:NSKeyValueObservingOptionNew context:&SLHEncoderItemKVOContext];
}

- (void)matchSource {
    BOOL hasAudio = NO, hasVideo = NO;
    
    for (MPVPlayerItemTrack *t in _playerItem.tracks) {

        switch (t.mediaType) {
                
            case MPVMediaTypeVideo:
            {
                if (hasVideo) {
                    break;
                }
                
                SLHEncoderItemOptions *vOptions = _videoOptions;
                NSSize vSize = t.videoSize;
                vOptions.videoHeight = vSize.height;
                vOptions.videoWidth = vSize.width;
                NSUInteger vBitrate = t.bitRate;
                vBitrate = (vBitrate) ? vBitrate / 1000 : (_playerItem.bitRate / 1000) - 128;
                vOptions.maxBitrate = vBitrate << 1;
                vOptions.bitRate = vBitrate;
                _videoStreamIndex = t.trackIndex;
                hasVideo = YES;
            }
                break;
                
            case MPVMediaTypeAudio:
            {
                if (hasAudio) {
                    break;
                }
                
                SLHEncoderItemOptions *aOptions = _audioOptions;
                NSUInteger aBitrate = t.bitRate;
                aOptions.bitRate = (aBitrate) ? aBitrate / 1000  : 128;
                aOptions.numberOfChannels = t.numberOfChannels;
                aOptions.sampleRate = t.sampleRate;
                _audioStreamIndex = t.trackIndex;
                hasAudio = YES;
            }
                break;
                
            default:
                break;
        }
        if (hasAudio && hasVideo) {
            break;
        }
    }
    self.intervalStart = 0;
    self.intervalEnd = _playerItem.duration;
}

- (instancetype)initWithPlayerItem:(MPVPlayerItem *)item {
    NSString *path = item.url.path;
    NSString *ext = path.pathExtension;
    path = [path stringByDeletingPathExtension];
    path = [NSString stringWithFormat:@"%@_%lu.%@", path, time(0), ext];
    return [self initWithPlayerItem:item outputPath:path];
}

- (void)dealloc {
    [_videoOptions removeObserver:self forKeyPath:@"bitRate" context:&SLHEncoderItemKVOContext];
    [_audioOptions removeObserver:self forKeyPath:@"bitRate" context:&SLHEncoderItemKVOContext];
    [self removeObserver:self forKeyPath:@"intervalStart" context:&SLHEncoderItemKVOContext];
    [self removeObserver:self forKeyPath:@"intervalEnd" context:&SLHEncoderItemKVOContext];
}

#pragma mark - KVO

static char SLHEncoderItemKVOContext;

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == &SLHEncoderItemKVOContext) {
        NSUInteger videoBitrate = 0, audioBitrate = 0;
        if (_videoStreamIndex > -1) {
            videoBitrate = _videoOptions.bitRate;
        }
        if (_audioStreamIndex > -1) {
            audioBitrate = _audioOptions.bitRate;
        }
        double duration = _interval.end - _interval.start;
        self.estimatedSize = ((videoBitrate + audioBitrate) * duration / 8192) * (1 << 20);
        self.duration = duration;
    }
}

#pragma mark - Bindings


- (void)setVideoOptions:(SLHEncoderItemOptions *)videoOptions {
    [_videoOptions removeObserver:self forKeyPath:@"bitRate" context:&SLHEncoderItemKVOContext];
    _videoOptions = videoOptions;
    [_videoOptions addObserver:self forKeyPath:@"bitRate" options:NSKeyValueObservingOptionNew context:&SLHEncoderItemKVOContext];
}

- (void)setAudioOptions:(SLHEncoderItemOptions *)audioOptions {
    [_audioOptions removeObserver:self forKeyPath:@"bitRate" context:&SLHEncoderItemKVOContext];
    _audioOptions = audioOptions;
    [_audioOptions addObserver:self forKeyPath:@"bitRate" options:NSKeyValueObservingOptionNew context:&SLHEncoderItemKVOContext];
}

- (double)intervalStart {
    return _interval.start;
}

- (void)setIntervalStart:(double)val {
    _interval.start = val;
}

- (double)intervalEnd {
    return _interval.end;
}

- (void)setIntervalEnd:(double)val {
    _interval.end = val;
}

- (NSString *)outputFileName {
    return _outputPath.lastPathComponent;
}

- (void)setOutputFileName:(NSString *)outputFileName {
    _outputPath = [NSString stringWithFormat:@"%@/%@", _outputPath.stringByDeletingLastPathComponent, outputFileName];
}

- (void)setNilValueForKey:(NSString *)key {
    NSNumber *value;
    if ([key isEqual:@"intervalEnd"]) {
        value = @(_playerItem.duration);
    } else {
        value = @(0);
    }

    [self setValue:value forKey:key];

}

@end
