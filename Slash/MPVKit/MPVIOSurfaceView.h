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

- (nullable instancetype)initWithFrame:(NSRect)frame
                                player:(nullable MPVPlayer *)player
                                 error:(out NSError **)error NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;

@property (nonatomic, nullable) MPVPlayer *player;

- (void)destroyRenderContext;

@end

NS_ASSUME_NONNULL_END
