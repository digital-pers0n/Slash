//
//  SLHStackView.m
//  Slash
//
//  Created by Terminator on 2019/11/10.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHStackView.h"
#import "SLHDisclosureView.h"

@interface SLHStackView () <SLHDisclosureViewDelegate>
@end

@implementation SLHStackView

#pragma mark - Overrides

- (void)addSubview:(NSView *)view {
    
    if (![view isKindOfClass:[SLHDisclosureView class]]) {
        SLHDisclosureView *v = [[SLHDisclosureView alloc] initWithFrame:view.frame];
        v.contentView = view;
        v.autoresizingMask = view.autoresizingMask;
        view = v;
    }
    
    NSArray *subviews = self.subviews;
    
    if (subviews.count) { // if we have subviews, resize and add new one to the bottom
        NSView *lastView = subviews.lastObject;
        NSRect newFrame = view.frame;
        NSRect frame = self.frame;
        newFrame.origin.y = NSMinY(lastView.frame) - NSHeight(newFrame);
        
        if (NSMinY(newFrame) < 0) {
            frame.size.height -= NSMinY(newFrame);
            self.frame = frame;
            
            for (NSView *subview in subviews) {
                NSRect viewFrame = subview.frame;
                viewFrame.origin.y -= NSMinY(newFrame);
            }
            newFrame.origin.y = 0;
        }
        
        newFrame.size.width = NSWidth(frame);
        view.frame = newFrame;
    } else {
        
        NSRect newFrame = view.frame;
        NSRect bounds = self.bounds;
        newFrame.origin.y = NSHeight(bounds) - NSHeight(newFrame);
        newFrame.size.width = NSWidth(bounds);
        view.frame = newFrame;
    }
    
    SLHDisclosureView *dv = (id)view;
    dv.delegate = self;
    [super addSubview:view];
}

#pragma mark - DisclosureView Delegate

/* This method is based on a similar method from an acient project "CollapsibleBox" from Apple Developer Portal (the project was removed from there long time ago) */
- (void)disclosureView:(SLHDisclosureView *)view didChangeRect:(NSRect)oldFrame toRect:(NSRect)newFrame {
    
    // Compare newFrame with targetView's current frame, to get the change in the origin y coordinate.  This is the amount by which we will shift all of the siblings of targetView that are below it.
    CGFloat yOffset = NSMinY(newFrame) - NSMinY(oldFrame);
    
    
    // Now identify all of the siblings of targetView that reside below it in the window.
    CGFloat height = NSHeight(newFrame);
    NSArray *siblingViews = self.subviews;
    for (NSView *sibling in siblingViews) {
        if (sibling != view) {
            NSRect oldSiblingFrame = sibling.frame;
            height += NSHeight(oldSiblingFrame);
            
            // If sibling is below the box we're expanding/collapsing, move it down/up to track with the expanding/collapsing box's motion.
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
