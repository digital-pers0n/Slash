//
//  SLTFilter.h
//  Slash
//
//  Created by Terminator on 2020/07/30.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SLTFilterKind) {
    SLTFilterKindVideo,
    SLTFilterKindAudio,
};

@class SLTFilterParameter;

@interface SLTFilter : NSObject <NSCopying>

- (instancetype)initWithFilterName:(NSString *)filterName
                       displayName:(NSString *)displayName
                              kind:(SLTFilterKind)kind;

/** FFmpeg filter name. */
@property (nonatomic) NSString *filterName;

/** Display name to use with UI elements. */
@property (nonatomic) NSString *displayName;

/** Determine if it's -af or -vf filter. */
@property (nonatomic) SLTFilterKind kind;

/** Indicate if the filter should be used. */
@property (nonatomic) BOOL enabled;

/** Array of filter parameters. */
@property (nonatomic) NSArray <SLTFilterParameter *> *parameters;

/** 
 Return a string to use with ffmpeg -vf or -af command line args.
 The string is constructed from elements inside the @c parameters array e.g.
 'filter=key1=value1:key2=value2'.
 If the filter doesn't have any paramters, return only the filterName.
 */
@property (nonatomic, readonly) NSString *stringValue;

@end

NS_ASSUME_NONNULL_END
