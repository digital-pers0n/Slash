//
//  SLHEmptyView.h
//  Slash
//
//  Created by Terminator on 2019/12/03.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * View that matches super view's width and height automatically 
 */
@interface SLHEmptyView : NSView

@property (nonatomic) IBInspectable NSString *stringValue;
@property (nonatomic) IBInspectable NSFont *font;
@property (nonatomic) IBInspectable NSColor *textColor;

@end

NS_ASSUME_NONNULL_END
