//
//  SLTMediaSettings.h
//  Slash
//
//  Created by Terminator on 2020/08/02.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - SLTMediaSettings

/** Base class for codec settings. */
@interface SLTMediaSettings : NSObject <NSCopying> {
    @package
    NSInteger _streamIndex;
    NSString *_codecName;
}

- (instancetype)initWithSettings:(SLTMediaSettings *)media;
- (instancetype)initWithCodecName:(NSString *)name streamIndex:(NSInteger)idx;
- (instancetype)initWithStreamIndex:(NSInteger)idx;

/** Index of the media stream. 
    Set to -1 to indicate that the stream should be ignored. */
@property (nonatomic) NSInteger streamIndex;
@property (nonatomic) NSString *codecName;

/** Array of ffmpeg arguments. Default implementation returns an empty array. */
@property (nonatomic, readonly) NSArray<NSString *> *arguments;

/** Array of ffmpeg arguments if the media stream should be copied. */
@property (nonatomic, readonly) NSArray<NSString *> *passThroughArguments;

/** Array of ffmpeg arguments if the media stream should be ignored. */
@property (nonatomic, readonly) NSArray<NSString *> *ignoredStreamArguments;

@end

#pragma mark - SLTAudioSettings
/** Generic Audio settings. */
@interface SLTAudioSettings : SLTMediaSettings <NSCopying> {
    @package
    int64_t _bitRate;
    NSInteger _sampleRate;
    NSInteger _numberOfChannels;
}

- (instancetype)initWithAudioSettings:(SLTAudioSettings *)audio;

/** Bitrate in bps. */
@property (nonatomic) int64_t bitRate;

/** Predefined sample rates. */
typedef NS_ENUM(NSInteger, SLTAudioSampleRate) {
    SLTAudioSampleRate32000 = 32000,
    SLTAudioSampleRate44100 = 44100,
    SLTAudioSampleRate48000 = 48000,
};
/** Sample rate in Hz. */
@property (nonatomic) NSInteger sampleRate;

/** Predefined channel values. */
typedef NS_ENUM(NSInteger, SLTAudioChannels) {
    SLTAudioChannelsMono    = 1,
    SLTAudioChannelsStereo  = 2,
    SLTAudioChannels51      = 6,
};
/** Number of audio channels. */
@property (nonatomic) NSInteger numberOfChannels;

@end

#pragma mark - SLTVideoSettings
/** Generic Video settings. */
@interface SLTVideoSettings : SLTMediaSettings <NSCopying> {
    @package
    int64_t _bitRate;
    NSString *_pixelFormat;
    NSInteger _maxGopSize;
}

- (instancetype)initWithVideoSettings:(SLTVideoSettings *)video;

/** Bitrate in bps. */
@property (nonatomic) int64_t bitRate;

/** Default value is yuv420p. */
@property (nonatomic) NSString *pixelFormat;

/** Group of picture (GOP) size. */
@property NSInteger maxGopSize;

@end

#pragma mark - SLTSubtitlesSettings
/** Generic Subtitles settings. Default codec name is `mov_text` */
@interface SLTSubtitlesSettings : SLTMediaSettings <NSCopying>
@end

NS_ASSUME_NONNULL_END
