//
//  SLHEncoderQueue.h
//  Slash
//
//  Created by Terminator on 2019/04/03.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SLHEncoderItem;

NS_ASSUME_NONNULL_BEGIN

@interface SLHEncoderQueue : NSWindowController

- (void)addEncoderItems:(NSArray <SLHEncoderItem *> *)array;

@property (readonly) BOOL inProgress;

@end

NS_ASSUME_NONNULL_END