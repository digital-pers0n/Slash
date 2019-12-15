//
//  SLHPlayerView.h
//  Slash
//
//  Created by Terminator on 2019/10/15.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class MPVPlayer, SLHPlayerViewController;

@interface SLHPlayerView : NSView

@property (nullable) MPVPlayer *player;
@property (getter=isReadyForDisplay, readonly) BOOL readyForDisplay;
@property (nonatomic, readonly) SLHPlayerViewController *viewController;

@end

NS_ASSUME_NONNULL_END
