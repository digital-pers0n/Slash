//
//  SLHMetadataEditor.h
//  Slash
//
//  Created by Terminator on 2019/03/04.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class SLHEncoderItem;

@interface SLHMetadataEditor : NSWindowController

@property SLHEncoderItem *encoderItem;
@property (readonly) BOOL hasWindow;

@end

NS_ASSUME_NONNULL_END