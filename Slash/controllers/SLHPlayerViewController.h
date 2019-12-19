//
//  SLHPlayerViewInlineController.h
//  Slash
//
//  Created by Terminator on 2019/10/16.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class MPVPlayer;

extern NSString * const SLHPlayerViewControllerDidChangeInMarkNotification;
extern NSString * const SLHPlayerViewControllerDidChangeOutMarkNotification;

@interface SLHPlayerViewController : NSViewController

@property (nullable) MPVPlayer *player;
@property (nullable) IBOutlet NSView *videoView;
@property (nonatomic) double inMark;
@property (nonatomic) double outMark;

- (void)loopPlaybackWithStart:(double)inMark end:(double)outMark;

@end

NS_ASSUME_NONNULL_END
