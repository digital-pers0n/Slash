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

@property (readonly) SLHMediaItem *mediaItem;

@property TimeInterval interval;

@property NSInteger videoStreamIndex;
@property NSInteger audioStreamIndex;
@property NSInteger subtitleStreamIndex;

@end

NS_ASSUME_NONNULL_END