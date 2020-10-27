//
//  SLTTask.h
//  Slash
//
//  Created by Terminator on 2020/9/28.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SLTSource, SLTDestination;

@interface SLTTask : NSObject <NSCopying>

+ (instancetype)taskWithSource:(SLTSource *)src
                   destination:(SLTDestination *)dst;

- (instancetype)initWithSource:(SLTSource *)src
                   destination:(SLTDestination *)dst;

@property (nonatomic) SLTSource *source;
@property (nonatomic) SLTDestination *destination;

#pragma mark - Template names

@property (class, null_resettable, nonatomic, copy) NSString *currentTemplateFormat;
+ (BOOL)validateTemplate:(NSString *)format error:(NSError **)error;

/**
 Format specifiers:
 @c %f - filename
 @c %d - date yyyymmdd_HHMMSS
 @c %D - date as seconds
 @c %r - selection range formatted as HH_MM_SS.MS e.g. 00_01_04.344-00_03_55.183
 @c %R - same as @c %r but uses unformatted time in seconds
 
 Default is "%f-%D"
 */
@property (null_resettable, nonatomic, copy) NSString *templateFormat;

/**
 Create a new destination file name, the value of @c templateNameFormat property
 is used.
 */
- (void)generateDestinationFileName;

@end

extern NSString *const SLTDefaultTemplateFormat;

NS_ASSUME_NONNULL_END
