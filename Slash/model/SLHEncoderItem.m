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

@implementation SLHEncoderItem

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    SLHEncoderItem *item = [[self.class allocWithZone:zone] init];
    
    item->_mediaItem = _mediaItem;
    item->_outputPath = _outputPath.copy;
    item->_container = _container.copy;
    
    item->_interval = _interval;
    item->_videoStreamIndex = _videoStreamIndex;
    item->_audioStreamIndex = _audioStreamIndex;
    item->_subtitlesStreamIndex = _subtitlesStreamIndex;
    
    item->_videoOptions = _videoOptions.copy;
    item->_audioOptions = _audioOptions.copy;
    item->_filters = _filters.copy;
    
    item->_twoPassEncoding = _twoPassEncoding;
    
    item->_metadata = _metadata.copy;
    item->_tag = _tag;

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
        _audioOptions = [SLHEncoderItemOptions new];
        _filters = [SLHFilterOptions new];
        _filters.subtitlesStyle = @"FontName=Skia,FontSize=14,OutlineColour=&H00000000,BorderStyle=3,Outline=1";
        _metadata = [[SLHEncoderItemMetadata alloc] initWithMediaItem:item];
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
                vBitrate = (vBitrate) ? vBitrate / 1000 : (item->_mediaItem.bitRate / 1000) - 128;
                vOptions.maxBitrate = vBitrate << 1;
                vOptions.bitRate = vBitrate;
                item->_videoStreamIndex = t.trackIndex;
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
                item->_audioStreamIndex = t.trackIndex;
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
    NSString *source = [NSString stringWithFormat:@"%@\n:: %@, %.0fx%.0f, %lukb, %lukbs, %.3fs", _mediaItem.filePath, codecName, vSize.width, vSize.height, _mediaItem.fileSize / 1024, _mediaItem.bitRate / 1000, _mediaItem.duration];
    
    // Output file
    double duration = _interval.end - _interval.start;
    NSUInteger bitRate = _videoOptions.bitRate + _audioOptions.bitRate;
    NSUInteger estimatedSize = (bitRate * duration / 8192) * 1024; // since bitrate in kbps multiply by 1024
    NSString *output = [NSString stringWithFormat:@"%@\n:: %@, %lux%lu, %lukb, %lukbs, %.3fs", _outputPath, _videoOptions.codecName,  _videoOptions.videoWidth, _videoOptions.videoHeight, estimatedSize, bitRate, duration];
    
    NSString *result = [NSString stringWithFormat:@"Output:\n%@\n\n"
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
