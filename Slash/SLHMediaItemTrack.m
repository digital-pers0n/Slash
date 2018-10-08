//
//  SLHMediaItemTrack.m
//  Slash
//
//  Created by Terminator on 2018/08/16.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import "SLHMediaItemTrack.h"

@implementation SLHMediaItemTrack

- (instancetype)init {
    return [self initWithTrackIndex:0 mediaType:SLHMediaTypeUnknown codecName:@"" encodingProfile:@""];
}

- (instancetype)initWithTrackIndex:(NSUInteger)idx mediaType:(SLHMediaType)type codecName:(NSString *)name encodingProfile:(NSString *)profile {
    self = [super init];
    if (self) {
        _trackIndex = idx;
        _mediaType = type;
        _codecName = name;
        _encodingProfile = profile;
        _videoSize = NSZeroSize;
        _pixelFormat = @"";
        _numberOfChannels = 0;
        _channelLayout = @"";
        _sampleRate = @"";
    }
    return self;
}

@end
