//
//  MPVPlayerItemTrack.h
//  Slash
//
//  Created by Terminator on 2019/10/21.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MPVMediaType) {
    MPVMediaTypeVideo,
    MPVMediaTypeAudio,
    MPVMediaTypeText,
    MPVMediaTypeData,
    MPVMediaTypeAttachment,
    MPVMediaTypeUnknown = INT_MAX
};

@class MPVMetadataItem;

@interface MPVPlayerItemTrack : NSObject

- (instancetype)init NS_UNAVAILABLE;

/**
 * Index of this track.
 */
@property (nonatomic, readonly) NSUInteger trackIndex;

/**
 * Media type of this track.
 */
@property (nonatomic, readonly) MPVMediaType mediaType;

/**
 * Media type as a string
 */
@property (nonatomic, readonly) NSString *mediaTypeName;

@property (nonatomic, readonly) NSString *codecName;

@property (nonatomic, readonly) NSString *codecLongName;

@property (nonatomic, readonly) NSString *pixFormatName;

@property (nonatomic, readonly) NSString *profileName;

@property (nonatomic, readonly) NSUInteger level;

@property (nonatomic, readonly) NSSize videoSize;

@property (nonatomic, readonly) NSSize codedVideoSize;

@property (nonatomic, readonly) NSString *fieldOrder;

@property (nonatomic, readonly) BOOL interlaced;

/**
 * Language code of this track.
 */
@property (nonatomic, readonly) NSString *language;

/**
 * Indicate start time in seconds. May be 0.
 */
@property (nonatomic, readonly) double startTime;

/**
 * Duration of this track in seconds. May be 0.
 */
@property (nonatomic, readonly) double duration;

/**
 * Bitrate in bps. May be 0.
 */
@property (nonatomic, readonly) uint64_t bitRate;

/**
 * Number of frames in this track. May be 0. 
 */
@property (nonatomic, readonly) uint64_t numberOfFrames;

/**
 * Sample aspect ratio of this track or NSZeroSize
 */
@property (nonatomic, readonly) NSSize sampleAspectRatio;

/**
 * Display aspect ratio or NSZeroSize
 */
@property (nonatomic, readonly) NSSize displayAspectRatio;

/**
 * Metadata items of this track
 */
@property (nonatomic, readonly) NSArray <MPVMetadataItem *> *metadata;

/**
 * Average frame rate
 */
@property (nonatomic, readonly) double averageFrameRate;

/**
 * Real base frame rate. The lowest framerate that can represent all timestamps.
 */
@property (nonatomic, readonly) double realBaseFrameRate;


#pragma mark - Audio

@property (nonatomic, readonly) NSUInteger numberOfChannels;
@property (nonatomic, readonly) NSString *channelLayout;
@property (nonatomic, readonly) NSString *sampleFormatName;
@property (nonatomic, readonly) NSUInteger sampleRate;


#pragma mark - Private

- (instancetype)initWithFormat:(void *)format stream:(void *)stream;

@end

NS_ASSUME_NONNULL_END
