//
//  SLHMediaItemTrack.h
//  Slash
//
//  Created by Terminator on 2018/08/16.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SLHMediaType) {
    SLHMediaTypeVideo,
    SLHMediaTypeAudio,
    SLHMediaTypeText,
    SLHMediaTypeUnknown = INT_MAX
};

@interface SLHMediaItemTrack : NSObject

/**
 Index of this track.
 */
@property NSUInteger trackIndex;

/**
 Media type of this track.
 */
@property SLHMediaType mediaType;

/**
 Indicate codec name
 */
@property NSString *codecName;

@property NSString *encodingProfile;

/**
 Indicate the video dimension.
 */
@property NSSize videoSize;

/**
 Indicate pixel format
 */
@property NSString *pixelFormat;


@property NSUInteger numberOfChannels;
@property NSString *channelLayout;
@property NSString *sampleRate;

@end
