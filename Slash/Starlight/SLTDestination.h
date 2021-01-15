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
@protocol SLTDestinationDataSource;

@interface SLTDestination : NSObject <NSCopying>

+ (instancetype)destinationWithPath:(NSString *)path
                           settings:(SLTEncoderSettings *)settings;

- (instancetype)initWithPath:(NSString *)path
                    settings:(SLTEncoderSettings *)settings;

@property (nonatomic, assign) id<SLTDestinationDataSource> dataSource;

/** Access the output file path. */
@property (nonatomic) NSString *filePath;

/** Same as filePath.lastPathComponent */
@property (nonatomic) NSString *fileName;

@property (nonatomic) SLTEncoderSettings *settings;
@property (nonatomic) NSArray<SLTFilter *> *videoFilters;
@property (nonatomic) NSArray<SLTFilter *> *audioFilters;
@property (nonatomic) NSDictionary<NSString *, NSString *> *metadata;

/** Set the stat time in seconds. */
@property (nonatomic) CGFloat startTime;

/** Set the end time in seconds. */
@property (nonatomic) CGFloat endTime;

/** Time duration to use with KVO and bindings. */
@property (nonatomic, readonly) CGFloat duration;
@property (nonatomic, readonly) int64_t estimatedFileSize;

typedef struct SLTTimeInterval_ {
    CGFloat start;
    CGFloat end;
} SLTTimeInterval;

@property (nonatomic) SLTTimeInterval selectionRange;

@end

@protocol SLTDestinationDataSource

/** Called when audio passthrough is enabled. */
- (int64_t)desiredAudioBitrate;

/** Called when video passthrough is enabled. */
- (int64_t)desiredVideoBitrate;
@end

NS_ASSUME_NONNULL_END
