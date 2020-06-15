//
//  MPVIOSurfaceView.h
//  Slash
//
//  Created by Terminator on 2020/06/13.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class MPVPlayer;

@interface MPVIOSurfaceView : NSView

- (instancetype)initWithPlayer:(nullable MPVPlayer *)player;
@property (nonatomic, nullable) MPVPlayer *player;

@end

NS_ASSUME_NONNULL_END
