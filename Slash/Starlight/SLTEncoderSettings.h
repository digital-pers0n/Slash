//
//  SLTEncoderSettings.h
//  Slash
//
//  Created by Terminator on 2020/08/02.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SLTVideoSettings, SLTAudioSettings, SLTSubtitlesSettings;

@interface SLTEncoderSettings : NSObject <NSCopying>

- (instancetype)initWithVideo:(SLTVideoSettings *)video
                        audio:(SLTAudioSettings *)audio
                    subtitles:(SLTSubtitlesSettings *)subs;

@property (class, nonatomic, copy) NSString *ffmpegPath;
@property (class, nonatomic) NSInteger numberOfThreads;

@property (nonatomic, readonly) BOOL allowsTwoPassEncoding;
@property (nonatomic, readonly) BOOL allowsAudioFilters;
@property (nonatomic, readonly) BOOL allowsVideoFilters;
@property (nonatomic, readonly, nullable) NSArray<NSString *> *firstPassArguments;
@property (nonatomic, readonly, nullable) NSArray<NSString *> *arguments;
@property (nonatomic) BOOL enableVideoPassThrough;
@property (nonatomic) BOOL enableAudioPassThrough;
@property (nonatomic) SLTVideoSettings *videoSettings;
@property (nonatomic) SLTAudioSettings *audioSettings;
@property (nonatomic) SLTSubtitlesSettings *subtitlesSettings;
@property (class, readonly) NSArray <NSString *> *allowedContainers;
@property (nonatomic) NSString *containerName;

@end

NS_ASSUME_NONNULL_END
