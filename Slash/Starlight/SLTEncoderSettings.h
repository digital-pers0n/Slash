//
//  SLTEncoderSettings.h
//  Slash
//
//  Created by Terminator on 2020/08/02.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SLTVideoSettings, SLTAudioSettings;

@interface SLTEncoderSettings : NSObject <NSCopying>
@property (nonatomic, readonly) BOOL allowsTwoPassEncoding;
@property (nonatomic, readonly, nullable) NSArray<NSString *> *firstPassArguments;
@property (nonatomic) BOOL enableVideoPassThrough;
@property (nonatomic) BOOL enableAudioPassThrough;
@property (nonatomic) SLTVideoSettings *videoSettings;
@property (nonatomic) SLTAudioSettings *audioSettings;
@property (nonatomic) NSArray <NSString *> *allowedContainers;
@property (nonatomic) NSString *containerName;

@end

NS_ASSUME_NONNULL_END
