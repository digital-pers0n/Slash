//
//  SLHSliderCell.m
//  Slash
//
//  Created by Terminator on 2019/10/29.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHSliderCell.h"

@implementation SLHSliderCell

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _markColor = [NSColor whiteColor];
        _selectionColor = [NSColor selectedControlColor];
    }
    return self;
}

- (BOOL)startTrackingAt:(NSPoint)startPoint inView:(NSView *)controlView {
    
    BOOL value = [super startTrackingAt:startPoint inView:controlView];
    [_delegate sliderCellMouseDown:self];
    return value;
}

- (BOOL)continueTracking:(NSPoint)lastPoint at:(NSPoint)currentPoint inView:(NSView *)controlView {
    
    BOOL value = [super continueTracking:lastPoint at:currentPoint inView:controlView];
    [_delegate sliderCellMouseDragged:self];
    return value;
}

- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)stopPoint inView:(NSView *)controlView mouseIsUp:(BOOL)flag {
    
    [super stopTracking:lastPoint at:stopPoint inView:controlView mouseIsUp:flag];
    [_delegate sliderCellMouseUp:self];
}

- (void)drawBarInside:(NSRect)rect flipped:(BOOL)flipped {
    [super drawBarInside:rect flipped:flipped];
    double maxValue = self.maxValue;
    if ( _outMark == 0 || maxValue == 0) { return; }
    CGFloat inX = round(_inMark / maxValue * NSWidth(rect));
    CGFloat outX = round(_outMark / maxValue * NSWidth(rect));
    
    rect.origin.y += 1;
    rect.size.height -= 2;
    
    rect.size.width = outX - inX;
    rect.origin.x = inX;
    
    [_selectionColor set];
    NSRectFill(rect);
    
    rect.size.width = 1;
    [_markColor set];
    NSRectFill(rect);
    
    rect.origin.x = outX;
    NSRectFill(rect);
}

@end
