//
//  SLKFFmpegInfoController.h
//  Slash
//
//  Created by Terminator on 2021/4/30.
//  Copyright © 2021年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN
@class SLTFFmpegInfo;

@interface SLKFFmpegInfoController : NSWindowController

+ (instancetype)sharedInstance;

@property (nonatomic, readonly, nullable) SLTFFmpegInfo *info;
- (void)updateInfoWithPath:(nullable NSString *)ffmpegPath;

@end

NS_ASSUME_NONNULL_END
