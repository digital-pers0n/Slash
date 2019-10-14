//
//  MPVOpenGLView.h
//  Slash
//
//  Created by Terminator on 2019/10/14.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class MPVPlayer;

@interface MPVOpenGLView : NSOpenGLView

- (instancetype)initWithPlayer:(nullable MPVPlayer *)player;
@property (nonatomic, nullable) MPVPlayer *player;

@end

NS_ASSUME_NONNULL_END
