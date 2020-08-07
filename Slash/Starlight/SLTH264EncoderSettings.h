//
//  SLTH264EncoderSettings.h
//  Slash
//
//  Created by Terminator on 2020/08/06.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLTEncoderSettings.h"
#import "SLTMediaSettings.h"

NS_ASSUME_NONNULL_BEGIN

@class SLTH264VideoSettings, SLTH264AudioSettings;

#pragma mark - SLTH264EncoderSettings
@interface SLTH264EncoderSettings : SLTEncoderSettings

@property (nonatomic) BOOL enableTwoPassEncoding;
/** 
 Value of this property is ignored if the enableTwoPassEncoding is set to YES.
 */
@property (nonatomic) BOOL enableCRFEncoding;

@end

#pragma mark - SLTH264VideoSettings
@interface SLTH264VideoSettings : SLTVideoSettings

@property (nonatomic) int64_t maxRate;
@property (nonatomic) NSInteger crf;


@end

#pragma mark - SLTH264AudioSettings
@interface SLTH264AudioSettings : SLTAudioSettings

@property (nonatomic) int64_t bitRate;

@end

NS_ASSUME_NONNULL_END
