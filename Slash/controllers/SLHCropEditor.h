//
//  SLHCropEditor.h
//  Slash
//
//  Created by Terminator on 2019/03/26.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SLHEncoderItem;

@interface SLHCropEditor : NSWindowController

+ (NSRect)cropRectForItem:(SLHEncoderItem *)item;

@property SLHEncoderItem *encoderItem;
@property BOOL hasWindow;

@end
