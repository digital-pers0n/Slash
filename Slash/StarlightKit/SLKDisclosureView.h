//
//  SLKDisclosureView.h
//  Slash
//
//  Created by Terminator on 2020/8/19.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLKDisclosureView : NSView {
    @package
    NSRect _currentFrame;
}

@property (nonatomic) IBInspectable NSString *title;
@property (nonatomic, nullable, weak) IBOutlet NSView *contentView;
@property (nonatomic, readonly) NSRect currentFrame;

@end

/** 
 Same as SLKDisclosureView, but uses the title cell with a checkbox.
 The class exposes NSValueBinding, so it can be bound to an object.
 */
@interface SLKCheckboxDisclosureView : SLKDisclosureView
@end

NS_ASSUME_NONNULL_END
