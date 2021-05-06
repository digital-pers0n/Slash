//
//  SLTFFmpegInfo.h
//  Slash
//
//  Created by Terminator on 2020/11/2.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLTFFmpegInfo : NSObject
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

- (nullable instancetype)initWithPath:(NSString *)ffmpegPath
                              handler:(void(^)(NSError *e))errorBlock;

@property (nonatomic, readonly) NSString *path;
@property (nonatomic, readonly) NSArray<NSString*> *filters;
@property (nonatomic, readonly) NSArray<NSString*> *audioFilters;
@property (nonatomic, readonly) NSArray<NSString*> *videoFilters;
@property (nonatomic, readonly) NSArray<NSString*> *encoders;
@property (nonatomic, readonly) NSArray<NSString*> *audioEncoders;
@property (nonatomic, readonly) NSArray<NSString*> *videoEncoders;
@property (nonatomic, readonly) NSArray<NSString*> *subtitlesEncoders;

- (BOOL)hasEncoder:(NSString *)name;
- (BOOL)hasFilter:(NSString *)name;
@property (nonatomic, readonly) NSString *versionString;
@property (nonatomic, readonly) NSString *buildConfigurationString;

@end

NS_ASSUME_NONNULL_END
