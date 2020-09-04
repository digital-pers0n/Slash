//
//  SLKStackView.h
//  Slash
//
//  Created by Terminator on 2020/8/31.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class SLKDisclosureView;

/**
 Simple stack view with collapsible subviews.
 
 @note
 To work correctly it must be embedded into a scroll view.
 
 Subviews added using -addSubview: method must be instances of SLKDisclosureView 
 class. Other subviews must be added using -addSubview:withTitle: method.
 */
@interface SLKStackView : NSView

/** Newly added views are stacked on top of old ones. */
- (void)addSubview:(SLKDisclosureView *)view;
- (void)addSubview:(NSView *)view withTitle:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
