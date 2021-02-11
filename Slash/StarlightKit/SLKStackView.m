//
//  SLKStackView.m
//  Slash
//
//  Created by Terminator on 2020/8/31.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLKStackView.h"
#import "SLKDisclosureView.h"

#import "SLTDefines.h"
#import "SLTObserver.h"

#import "MPVKitDefines.h"

OBJC_DIRECT_MEMBERS
@implementation SLKStackView

#pragma mark - Overrides

- (void)addSubview:(SLKDisclosureView *)view {
    NSAssert([view isKindOfClass:[SLKDisclosureView class]],
             @"View must be an instance of SLKDisclosureView class");
    NSArray *subviews = self.subviews;
    NSRect newFrame = view.frame;
    NSRect frame = self.frame;
    if (subviews.count) {
        NSView *lastView = subviews.lastObject;
        newFrame.origin.y = NSMinY(lastView.frame) - NSHeight(newFrame);
        if (NSMinY(newFrame) < 0) {
            frame.size.height -= NSMinY(newFrame);
            self.frame = frame;
            newFrame.origin.y = 0;
        }
    } else {
        newFrame.origin.y = NSHeight(frame) - NSHeight(newFrame);
    }
    newFrame.size.width = NSWidth(frame);
    view.autoresizingMask =
                      NSViewMinXMargin | NSViewMinYMargin | NSViewWidthSizable;
    view.frame = newFrame;
    
    UNSAFE typeof(self) u = self;
    [view addObserver:self keyPath:KVP(view, currentFrame)
              options:NSKeyValueObservingOptionOld handler:
     ^(SLKDisclosureView *obj, NSString *keyPath, NSDictionary *change) {
         NSRect rect = [[change objectForKey:NSKeyValueChangeOldKey] rectValue];
         [u disclosureView:obj didResize:rect];
     }];
    [super addSubview:view];
}

- (BOOL)isFlipped {
    return YES;
}

- (void)willRemoveSubview:(NSView *)subview {
    [subview invalidateObserver:self
                        keyPath:KEYPATH(SLKDisclosureView, currentFrame)];
    [super willRemoveSubview:subview];
}

#pragma mark - Methods

- (void)addSubview:(NSView *)view withTitle:(NSString *)title {
    SLKDisclosureView *v = [[SLKDisclosureView alloc] init];
    v.title = title;
    v.contentView = view;
    [self addSubview:v];
}

- (void)disclosureView:(SLKDisclosureView *)dv didResize:(NSRect)oldFrame {
    NSRect newFrame = dv->_currentFrame;
    CGFloat yOffset = NSMinY(newFrame) - NSMinY(oldFrame);
    
    CGFloat height = NSHeight(newFrame);
    NSArray *subviews = self.subviews;
    for (NSView *sibling in subviews) {
        if (sibling != dv) {
            NSRect oldSiblingFrame = sibling.frame;
            height += NSHeight(oldSiblingFrame);
            
            if (NSMinY(oldSiblingFrame) < NSMinY(oldFrame)) {
                NSRect newSiblingFrame = oldSiblingFrame;
                newSiblingFrame.origin.y += yOffset;
                sibling.frame = newSiblingFrame;
            }
        }
    }
    NSRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

@end
