//
//  SLHEncoderItem.h
//  Slash
//
//  Created by Terminator on 2018/11/15.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct time_interval {
    double start;
    double end;
} TimeInterval;

@class SLHMediaItem;

@interface SLHEncoderItem : NSObject

- (instancetype)initWithMediaItem:(SLHMediaItem *)item;
- (instancetype)initWithMediaItem:(SLHMediaItem *) item outputPath:(NSString *)outputMediaPath NS_DESIGNATED_INITIALIZER;

@property (readonly) SLHMediaItem *mediaItem;
@property NSString *outputPath;
@property NSString *container;

@property TimeInterval interval;

@property NSInteger videoStreamIndex;
@property NSInteger audioStreamIndex;
@property NSInteger subtitleStreamIndex;

@property NSMutableDictionary *videoOptions;
@property NSMutableDictionary *videoFilters;

@property NSMutableDictionary *audioOptions;
@property NSMutableDictionary *audioFilters;

@property NSMutableDictionary *metadata;

@end

NS_ASSUME_NONNULL_END