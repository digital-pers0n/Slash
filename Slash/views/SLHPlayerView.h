//
//  SLHPlayerView.h
//  Slash
//
//  Created by Terminator on 2019/10/15.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class MPVPlayer;

typedef NS_ENUM(NSInteger, MPVPlayerViewControlsStyle) {
    MPVPlayerViewControlsStyleNone,
    MPVPlayerViewControlsStyleInline,
    MPVPlayerViewControlsStyleFloating,
    MPVlayerViewControlsStyleDefault = MPVPlayerViewControlsStyleInline
};

@interface SLHPlayerView : NSView

@property (nullable) MPVPlayer *player;
@property MPVPlayerViewControlsStyle controlsStyle;
@property (getter=isReadyForDisplay, readonly) BOOL readyForDisplay;

@end


NS_ASSUME_NONNULL_END
