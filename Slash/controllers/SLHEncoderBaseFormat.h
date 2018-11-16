//
//  SLHEncoderBaseFormat.h
//  Slash
//
//  Created by Terminator on 2018/11/16.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SLHEncoderSettings.h"

@class SLHEncoderItem;

@interface SLHEncoderBaseFormat : NSViewController <SLHEncoderSettingsDelegate>

@property SLHEncoderItem *encoderItem;
- (NSView *)encoderSettings:(SLHEncoderSettings *)enc viewForTab:(SLHEncoderSettingsTab) tab;

@end
