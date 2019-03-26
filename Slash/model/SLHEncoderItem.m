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

@implementation SLHEncoderItem

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    SLHEncoderItem *item = [[SLHEncoderItem alloc] init];
    item.mediaItem = _mediaItem;
    item.outputPath = _outputPath.copy;
    item.container = _container.copy;
    item.interval = _interval;
    
    item.videoStreamIndex = _videoStreamIndex;
    item.audioStreamIndex = _audioStreamIndex;
    item.subtitlesStreamIndex = _subtitlesStreamIndex;
    
    item.videoOptions = _videoOptions.copy;
    item.videoFilters = _videoFilters.mutableCopy;
    item.audioOptions = _audioOptions.copy;
    item.audioFilters = _audioFilters.mutableCopy;
    item.filters = _filters.copy;
    
    item.twoPassEncoding = _twoPassEncoding;
    item.firstPassOptions = _firstPassOptions.mutableCopy;
    
    item.metadata = _metadata.mutableCopy;
    item.tag = _tag;
    [SLHEncoderItem matchSource:item];
    
    return item;
}

#pragma mark - Initialize

- (instancetype)initWithMediaItem:(SLHMediaItem *)item outputPath:(NSString *)outputMediaPath {
    self = [super init];
    if (self) {
        _mediaItem = item;
        _outputPath = outputMediaPath;
        _subtitlesStreamIndex = -1;
        _twoPassEncoding = NO;
        _videoOptions = [SLHEncoderItemOptions new];
        _videoFilters = @{}.mutableCopy;
        _audioOptions = [SLHEncoderItemOptions new];
        _audioFilters = @{}.mutableCopy;
        _filters = [SLHFilterOptions new];
        _firstPassOptions = @{}.mutableCopy;
        _metadata = @{}.mutableCopy;
        [SLHEncoderItem matchSource:self];
    }
    return self;
}

- (instancetype)initWithMediaItem:(SLHMediaItem *)item  {
    NSString *path = item.filePath;
    NSString *ext = path.pathExtension;
    path = [path stringByDeletingPathExtension];
    path = [NSString stringWithFormat:@"%@_%lu.%@", path, time(0), ext];
    return [self initWithMediaItem:item outputPath:path];
}

+ (void)matchSource:(SLHEncoderItem *)item {
    BOOL audio = NO, video = NO;
    
    for (SLHMediaItemTrack *t in item->_mediaItem.tracks) {
        switch (t.mediaType) {
            case SLHMediaTypeVideo:
            {
                SLHEncoderItemOptions *vOptions = item.videoOptions;
                NSSize vSize = t.videoSize;
                vOptions.videoHeight = vSize.height;
                vOptions.videoWidth = vSize.width;
                NSUInteger vBitrate = t.bitRate;
                vOptions.bitRate = (vBitrate) ? vBitrate / 1000 : (item->_mediaItem.bitRate / 1000) - 128;
                video = YES;
            }
                break;
                
            case SLHMediaTypeAudio:
            {
                SLHEncoderItemOptions *aOptions = item.audioOptions;
                NSUInteger aBitrate = t.bitRate;
                aOptions.bitRate = (aBitrate) ? aBitrate / 1000  : 128;
                aOptions.numberOfChannels = t.numberOfChannels;
                aOptions.sampleRate = t.sampleRate.integerValue;
                audio = YES;
            }
                break;
                
            default:
                break;
        }
        if (audio && video) {
            break;
        }
    }
}

#pragma mark - Info

- (NSString *)summary {
    
    // Source file
    NSSize vSize = NSZeroSize;
    NSString *codecName = nil;
    for (SLHMediaItemTrack *t in _mediaItem.tracks) {
        if (t.mediaType == SLHMediaTypeVideo) {
            vSize = t.videoSize;
            codecName = t.codecName;
            break;
        }
    }
    if (!codecName) { // Audio only?
        codecName = _mediaItem.tracks[0].codecName;
    }
    NSString *source = [NSString stringWithFormat:@"%@: %@, %.0fx%.0f, %lukb, %lukbs, %.3fs", _mediaItem.filePath, codecName, vSize.width, vSize.height, _mediaItem.fileSize / 1024, _mediaItem.bitRate / 1024, _mediaItem.duration];
    
    // Output file
    double duration = _interval.end - _interval.start;
    NSUInteger bitRate = _videoOptions.bitRate + _audioOptions.bitRate;
    NSUInteger estimatedSize = (bitRate * duration / 8192) * 1024; // since bitrate in kbps multiply by 1024
    NSString *output = [NSString stringWithFormat:@"%@: %@, %lux%lu, %lukb, %lukbs, %.3fs", _outputPath, _videoOptions.codecName,  _videoOptions.videoWidth, _videoOptions.videoHeight, estimatedSize, bitRate, duration];
    
    NSString *result = [NSString stringWithFormat:@"Output:\n%@\n"
                        @"Source:\n%@", output, source];
    
    return result;
}

#pragma mark - Bindings

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

@end
