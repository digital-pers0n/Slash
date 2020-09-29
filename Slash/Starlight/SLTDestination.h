//
//  SLTDestination.h
//  Slash
//
//  Created by Terminator on 2020/07/30.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SLTEncoderSettings, SLTFilter;

@interface SLTDestination : NSObject <NSCopying>

+ (instancetype)destinationWithPath:(NSString *)path
                           settings:(SLTEncoderSettings *)settings;

- (instancetype)initWithPath:(NSString *)path
                    settings:(SLTEncoderSettings *)settings;

/** Access the output file path. */
@property (nonatomic) NSString *filePath;

/** Same as filePath.lastPathComponent */
@property (nonatomic) NSString *fileName;

@property (nonatomic) SLTEncoderSettings *settings;
@property (nonatomic) NSArray<SLTFilter *> *videoFilters;
@property (nonatomic) NSArray<SLTFilter *> *audioFilters;
@property (nonatomic) NSDictionary<NSString *, NSString *> *metadata;

/** Set the in point in seconds. */
@property (nonatomic) CGFloat inPoint;

/** Set the out point in seconds. */
@property (nonatomic) CGFloat outPoint;

@end

NS_ASSUME_NONNULL_END
