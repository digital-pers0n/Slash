//
//  SLHEncoderItem.h
//  Slash
//
//  Created by Terminator on 2018/11/15.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SLHEncoderItemOptions.h"

NS_ASSUME_NONNULL_BEGIN

typedef struct time_interval {
    double start;
    double end;
} TimeInterval;

@class SLHMediaItem;

@interface SLHEncoderItem : NSObject <NSCopying>

- (instancetype)initWithMediaItem:(SLHMediaItem *)item;
- (instancetype)initWithMediaItem:(SLHMediaItem *) item outputPath:(NSString *)outputMediaPath;

@property SLHMediaItem *mediaItem;
@property NSString *outputPath;
@property NSString *outputFileName;
@property NSString *container;

@property TimeInterval interval;

@property NSInteger videoStreamIndex;
@property NSInteger audioStreamIndex;
@property NSInteger subtitlesStreamIndex;

@property SLHEncoderItemOptions *videoOptions;
@property NSMutableDictionary *videoFilters;

@property SLHEncoderItemOptions *audioOptions;
@property NSMutableDictionary *audioFilters;

@property BOOL twoPassEncoding;
@property NSMutableDictionary *firstPassOptions;

@property NSMutableDictionary *metadata;

@property (readonly) NSString * summary;

/* Cocoa Bindings */
@property double intervalStart;
@property double intervalEnd;

@end

NS_ASSUME_NONNULL_END