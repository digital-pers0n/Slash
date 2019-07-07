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

- (instancetype)initWithTrackIndex:(NSUInteger)idx mediaType:(SLHMediaType)type codecName:(NSString *)name encodingProfile:(NSString *)profile;

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
 Inciate teh video coded dimension.
 */
@property NSSize codedVideoSize;

/**
 Sample aspect ratio
 */
@property NSString *sampleAspectRatio;

/**
 Display aspect ratio
*/
@property NSString *displayAspectRatio;

/**
 Indicate pixel format
 */
@property NSString *pixelFormat;

/**
 Indicate language of the track
 */
@property NSString *language;

/**
 Bitrate of the track
 */
@property NSUInteger bitRate;

/**
 Frame rate of the track.
 */
@property double frameRate;

/**
 r_frame_rate
 From ffmpeg FAQ:
 The smallest frame rate that can accurately represent all timestamps.
 */
@property double rFrameRate;

@property NSUInteger numberOfChannels;
@property NSString *channelLayout;
@property NSString *sampleRate;

@end
