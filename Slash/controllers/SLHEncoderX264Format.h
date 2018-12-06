//
//  SLHEncoderX264Format.h
//  Slash
//
//  Created by Terminator on 2018/12/05.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import "SLHEncoderBaseFormat.h"

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

typedef NS_ENUM(NSUInteger, SLHX264ContainerType) {
    SLHX264ContainerMP4,
    SLHX264ContainerM4V,
    SLHX264ContainerMKV,
    SLHX264ContainerMOV
};

NS_ASSUME_NONNULL_BEGIN

@interface SLHEncoderX264Format : SLHEncoderBaseFormat

@property SLHX264EncodingType encodingType;
@property SLHX264PresetType presetType;
@property SLHX264ProfileType profileType;
@property NSUInteger videoWidth;
@property NSUInteger videoHeight;

/**
 Comma-separated strings.
 Valid strings: film animation grain stillimage psnr ssim fastdecode zerolatency
 */
@property NSString *tune;


@end

NS_ASSUME_NONNULL_END