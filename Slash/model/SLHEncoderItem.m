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
    
    item.twoPassEncoding = _twoPassEncoding;
    item.firstPassOptions = _firstPassOptions.mutableCopy;
    
    item.metadata = _metadata.mutableCopy;
    
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
        _firstPassOptions = @{}.mutableCopy;
        _metadata = @{}.mutableCopy;
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

#pragma mark - Info

- (NSString *)summary {
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
    NSString *input = [NSString stringWithFormat:@"%@: %@, %.0fx%.0f, %lukb, %lukbs, %.3fs", _mediaItem.filePath, codecName, vSize.width, vSize.height, _mediaItem.fileSize / 1024, _mediaItem.bitRate / 1024, _mediaItem.duration];
/* TODO: Generate output file info */
    NSString *output = @"(Not Implemented)";
    
    NSString *result = [NSString stringWithFormat:@"Output:\n%@\n"
                        @"Input:\n%@", output, input];
    
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
