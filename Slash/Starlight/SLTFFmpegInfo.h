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

- (nullable instancetype)initWithPath:(NSString *)path error:(NSError **)error;
@property (nonatomic, readonly) NSString *path;
@property (nonatomic, readonly) NSArray *supportedCodecs;
@property (nonatomic, readonly) NSArray *supportedFilters;
- (BOOL)hasCodec:(NSString *)name;
- (BOOL)hasFilter:(NSString *)name;
@property (nonatomic, readonly) NSString *versionString;
@property (nonatomic, readonly) NSString *buildConfigurationString;

@end

NS_ASSUME_NONNULL_END
