//
//  SLHSliderCell.m
//  Slash
//
//  Created by Terminator on 2019/10/29.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHSliderCell.h"

@implementation SLHSliderCell


- (BOOL)startTrackingAt:(NSPoint)startPoint inView:(NSView *)controlView {
    [_delegate sliderCellMouseDown:self];
    return [super startTrackingAt:startPoint inView:controlView];
}

- (BOOL)continueTracking:(NSPoint)lastPoint at:(NSPoint)currentPoint inView:(NSView *)controlView {
    [_delegate sliderCellMouseDragged:self];
    return [super continueTracking:lastPoint at:currentPoint inView:controlView];
}

- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)stopPoint inView:(NSView *)controlView mouseIsUp:(BOOL)flag {
    
    [super stopTracking:lastPoint at:stopPoint inView:controlView mouseIsUp:flag];
    [_delegate sliderCellMouseUp:self];
}

@end
