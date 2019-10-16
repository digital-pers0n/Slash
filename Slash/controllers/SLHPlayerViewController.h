//
//  SLHPlayerViewInlineController.h
//  Slash
//
//  Created by Terminator on 2019/10/16.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MPVPlayer;

@interface SLHPlayerViewController : NSViewController

@property (nullable) MPVPlayer *player;
@property (nullable) IBOutlet NSView *videoView;

@end
