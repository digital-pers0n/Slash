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
@interface SLTMediaSettings : NSObject {
    @package
    NSUInteger _streamIndex;
    NSString *_codecName;
}

/** Index of the media stream. */
@property (nonatomic) NSUInteger streamIndex;
@property (nonatomic) NSString *codecName;

/** Array of ffmpeg arguments. Default implementation returns nil. */
@property (nonatomic, readonly) NSArray <NSString *> *arguments;

@end

#pragma mark - SLTAudioSettings
/** Generic Audio settings. */
@interface SLTAudioSettings : SLTMediaSettings {
    @package
    int64_t _bitRate;
    NSInteger _sampleRate;
    NSInteger _numberOfChannels;
}

/** Bitrate in bps. */
@property (nonatomic) int64_t bitRate;

/** Sample rate in Hz. */
@property (nonatomic) NSInteger sampleRate;

/** Number of audio channels. */
@property (nonatomic) NSInteger numberOfChannels;

@end

#pragma mark - SLTVideoSettings
/** Generic Video settings. */
@interface SLTVideoSettings : SLTMediaSettings {
    @package
    int64_t _bitRate;
    NSString *_pixelFormat;
    NSInteger _maxGopSize;
}

/** Bitrate in bps. */
@property (nonatomic) int64_t bitRate;

/** Default value is yuv420p. */
@property (nonatomic) NSString *pixelFormat;

/** Group of picture (GOP) size. */
@property NSInteger maxGopSize;

@end

NS_ASSUME_NONNULL_END
