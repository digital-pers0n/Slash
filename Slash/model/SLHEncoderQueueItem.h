//
//  SLHEncoderQueueItem.h
//  Slash
//
//  Created by Terminator on 2019/05/18.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLHEncoderQueueItem : NSObject

@property NSArray *encoderArguments;
@property NSString *name;
@property NSUInteger numberOfFrames;
@property NSUInteger currentFrameNumber;
@property NSInteger tag;
@property BOOL encoded;
@property BOOL failed;

@end

NS_ASSUME_NONNULL_END