//
//  SLHCropView.h
//  Slash
//
//  Created by Terminator on 2019/11/22.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLHCropView : NSView

/** Current selection */
@property (nonatomic) IBInspectable NSRect selectionRect;

/** Content size */
@property (nonatomic) IBInspectable NSSize size;

/** Tint color */
@property (nonatomic) IBInspectable NSColor *tintColor;

/** Selection line color */
@property (nonatomic) IBInspectable NSColor *lineColor;

@end

NS_ASSUME_NONNULL_END
