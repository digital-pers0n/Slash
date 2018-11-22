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
