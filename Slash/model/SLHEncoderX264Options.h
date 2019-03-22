//
//  SLHEncoderX264Options.h
//  Slash
//
//  Created by Terminator on 2019/03/18.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHEncoderItemOptions.h"


typedef NS_ENUM(NSUInteger, SLHX264EncodingType) {
    SLHX264EncodingSinglePass,
    SLHX264EncodingTwoPass,
    SLHX264EncodingCRFSinglePass,
};

typedef NS_ENUM(NSUInteger, SLHX264PresetType) {
    SLHX264PresetUltrafast,
    SLHX264PresetSuperfast,
    SLHX264PresetVeryfast,
    SLHX264PresetFaster,
    SLHX264PresetFast,
    SLHX264PresetMedium,
    SLHX264PresetSlow,
    SLHX264PresetSlower,
    SLHX264PresetVeryslow,
    SLHX264PresetPlacebo,
    SLHX264PresetNone = NSUIntegerMax
};

typedef NS_ENUM(NSUInteger, SLHX264ProfileType) {
    SLHX264ProfileBaseline,
    SLHX264ProfileMain,
    SLHX264ProfileHigh,
    SLHX264ProfileNone = NSUIntegerMax
};

typedef NS_ENUM(NSUInteger, SLHX264LevelType) {
    SLHX264Level10,
    SLHX264Level11,
    SLHX264Level12,
    SLHX264Level13,
    SLHX264Level20,
    SLHX264Level21,
    SLHX264Level22,
    SLHX264Level30,
    SLHX264Level31,
    SLHX264Level32,
    SLHX264Level40,
    SLHX264Level41,
    SLHX264Level42,
    SLHX264Level50,
    SLHX264Level51,
    SLHX264LevelNone = NSUIntegerMax
};

typedef NS_ENUM(NSUInteger, SLHX264ContainerType) {
    SLHX264ContainerMP4,
    SLHX264ContainerM4V,
    SLHX264ContainerMKV,
    SLHX264ContainerMOV,
    SLHX264ContainerNone = NSUIntegerMax
};

typedef NS_ENUM(NSUInteger, SLHX264TuneType) {
    SLHX264TuneFilm,
    SLHX264TuneAnimation,
    SLHX264TuneGrain,
    SLHX264TuneStill,
    SLHX264TunePsnr,
    SLHX264TuneSsim,
    SLHX264TuneNone = NSUIntegerMax
};

@interface SLHEncoderX264Options : SLHEncoderItemOptions

- (instancetype)initWithOptions:(SLHEncoderItemOptions *)options;

@property SLHX264EncodingType encodingType;
@property SLHX264PresetType presetType;
@property SLHX264ProfileType profileType;
@property SLHX264LevelType levelType;

/**
 film animation grain stillimage psnr ssim fastdecode zerolatency
 */

@property SLHX264TuneType tuneType;
@property BOOL fastdecode;
@property BOOL zerolatency;

@end
