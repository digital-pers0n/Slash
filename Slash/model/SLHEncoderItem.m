//
//  SLHEncoderItem.m
//  Slash
//
//  Created by Terminator on 2018/11/15.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import "SLHEncoderItem.h"
#import "SLHMediaItem.h"

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
    item.subtitleStreamIndex = _subtitleStreamIndex;
    
    item.videoOptions = _videoOptions.mutableCopy;
    item.videoFilters = _videoFilters.mutableCopy;
    item.audioOptions = _audioOptions.mutableCopy;
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
        _subtitleStreamIndex = -1;
        _twoPassEncoding = NO;
        _videoOptions = @[].mutableCopy;
        _videoFilters = @[].mutableCopy;
        _audioOptions = @[].mutableCopy;
        _audioFilters = @[].mutableCopy;
        _firstPassOptions = @[].mutableCopy;
        _metadata = @[].mutableCopy;
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

@end
