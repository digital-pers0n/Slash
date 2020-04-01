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
#import "slh_video_frame_extractor.h"

#import "MPVPlayerItem.h"
#import "MPVPlayerItemTrack.h"

@interface SLHEncoderItem ()

@property (nonatomic) double duration;
@property (nonatomic) uint64_t estimatedSize;
@property (nonatomic, nullable) NSArray * previewImages;

@end

@implementation SLHEncoderItem

static NSUInteger _defaultNumberOfPreviewImages = 50;
static NSUInteger _defaultPreviewImageHeight = 128;

+ (void)setDefaultNumberOfPreviewImages:(NSUInteger)value {
    _defaultNumberOfPreviewImages = value;
}

+ (NSUInteger)defaultNumberOfPreviewImages {
    return _defaultNumberOfPreviewImages;
}

+ (void)setDefaultPreviewImageHeight:(NSUInteger)value {
    _defaultPreviewImageHeight = value;
}

+ (NSUInteger)defaultPreviewImageHeight {
    return _defaultPreviewImageHeight;
}

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
    
    // Share preview images across copies 
    item->_previewImages = _previewImages;

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
    [self addObserver:self forKeyPath:@"videoStreamIndex" options:NSKeyValueObservingOptionNew context:&SLHEncoderItemKVOContext];
    [self addObserver:self forKeyPath:@"audioStreamIndex" options:NSKeyValueObservingOptionNew context:&SLHEncoderItemKVOContext];
}

- (void)matchSource {
    MPVPlayerItemTrack *track = _playerItem.bestAudioTrack;
    NSUInteger aBitrate = 128;
    if (track) {
        SLHEncoderItemOptions *aOptions = _audioOptions;
        aBitrate = track.bitRate;
        aBitrate = (aBitrate) ? aBitrate / 1000 : 128;
        aOptions.bitRate = aBitrate;
        aOptions.numberOfChannels = track.numberOfChannels;
        aOptions.sampleRate = track.sampleRate;
        _audioStreamIndex = track.trackIndex;
    }
    
    track = _playerItem.bestVideoTrack;
    if (track) {
        SLHEncoderItemOptions *vOptions = _videoOptions;
        NSSize vSize = track.videoSize;
        vOptions.videoHeight = vSize.height;
        vOptions.videoWidth = vSize.width;
        NSUInteger vBitrate = track.bitRate;
        vBitrate = (vBitrate) ? vBitrate / 1000 : (_playerItem.bitRate / 1000) - aBitrate;
        vOptions.maxBitrate = vBitrate << 1;
        vOptions.bitRate = vBitrate;
        _videoStreamIndex = track.trackIndex;
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
    [_videoOptions removeObserver:self forKeyPath:@"maxBitrate" context:&SLHEncoderItemKVOContext];
    [_audioOptions removeObserver:self forKeyPath:@"bitRate" context:&SLHEncoderItemKVOContext];
    [self removeObserver:self forKeyPath:@"intervalStart" context:&SLHEncoderItemKVOContext];
    [self removeObserver:self forKeyPath:@"intervalEnd" context:&SLHEncoderItemKVOContext];
    [self removeObserver:self forKeyPath:@"videoStreamIndex" context:&SLHEncoderItemKVOContext];
    [self removeObserver:self forKeyPath:@"audioStreamIndex" context:&SLHEncoderItemKVOContext];
}

#pragma mark - KVO

static char SLHEncoderItemKVOContext;

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == &SLHEncoderItemKVOContext) {
        NSUInteger videoBitrate = 0, audioBitrate = 0;
        if (_videoStreamIndex > -1) {
            videoBitrate = _videoOptions.bitRate;
            
            if (videoBitrate == 0) {
                videoBitrate = _videoOptions.maxBitrate;
                
                if (videoBitrate == 0) {
                    videoBitrate = _playerItem.bitRate / 1024;
                }
            }

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
    [_videoOptions removeObserver:self forKeyPath:@"maxBitrate" context:&SLHEncoderItemKVOContext];
    _videoOptions = videoOptions;
    [_videoOptions addObserver:self forKeyPath:@"bitRate" options:NSKeyValueObservingOptionNew context:&SLHEncoderItemKVOContext];
    [_videoOptions addObserver:self forKeyPath:@"maxBitrate" options:NSKeyValueObservingOptionNew context:&SLHEncoderItemKVOContext];
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

#pragma mark - Preview Images

static CGSize rescaleSizeWithHeight(CGSize sourceSize, CGFloat newHeight) {
    CGFloat sourceHeight = sourceSize.height;
    CGFloat sourceWidth = sourceSize.width;
    CGFloat newWidth = sourceWidth * newHeight / sourceHeight;
    return CGSizeMake(newWidth, newHeight);
}

- (void)generatePreviewImagesWithBlock:(void (^)(BOOL))responseBlock {
    dispatch_queue_t queue;
    queue = dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0);
    
    dispatch_async(queue, ^{
        CFMutableArrayRef images;
        images = CFArrayCreateMutable(kCFAllocatorDefault,
                                      _defaultNumberOfPreviewImages,
                                      &kCFTypeArrayCallBacks);
        MPVPlayerItem * playerItem = self->_playerItem;
        const char * const path = playerItem.url.fileSystemRepresentation;
        CGSize vSize = rescaleSizeWithHeight(playerItem.bestVideoTrack.videoSize,
                                             _defaultPreviewImageHeight);
        int error = 0;
        error = vfe_get_keyframes(path, _defaultNumberOfPreviewImages,
                                  vSize, (void *)images, &vfe_reader);
        BOOL success = NO;
        if (!error) {
            self.previewImages = CFBridgingRelease(images);
            success = YES;
        }
        responseBlock(success);
    });
}


static void vfe_reader(void *ctx, double ts, CGImageRef image) {
    if (image) {
        CFMutableArrayRef images = (CFMutableArrayRef)ctx;
        CFArrayAppendValue(images, image);
        CFRelease(image);
    }
}

@end
