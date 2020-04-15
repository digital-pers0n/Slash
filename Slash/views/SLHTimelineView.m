//
//  SLHTimelineView.m
//  Slash
//
//  Created by Terminator on 2020/04/03.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLHTimelineView.h"
@import QuartzCore.CAShapeLayer;

@interface SLHTimelineView () {
    CAShapeLayer *_indicatorLayer;
    CGFloat _indicatorMargin;
    NSRect _indicatorFrame;
    NSRect _currentFrame;
    NSRect _workingArea;
    BOOL _mouseIn;
    NSTrackingArea *_trackingArea;
}

@end


@implementation SLHTimelineView

#pragma mark - Overrides

- (void)awakeFromNib {

    if (_maxValue == 0) {
        self.maxValue = 1;
    }
    _trackingArea = [NSTrackingArea new];

    _currentFrame = self.frame;
    _indicatorFrame = NSMakeRect(_indicatorMargin, 0, 1, NSHeight(_currentFrame));
    _workingArea = NSInsetRect(_currentFrame, _indicatorMargin, 0);
    
    _indicatorLayer = [CAShapeLayer new];
    _indicatorLayer.geometryFlipped = NO;
    _indicatorLayer.fillColor = [[NSColor systemRedColor] CGColor];
    _indicatorLayer.frame = _currentFrame;

    self.wantsLayer = YES;
    [self.layer addSublayer:_indicatorLayer];
}

- (void)setFrame:(NSRect)frame {
    _currentFrame = frame;
    _workingArea = NSInsetRect(_currentFrame, _indicatorMargin, 0);
    
    NSRect dvFrame = _documentView.frame;
    if (NSHeight(frame) < NSHeight(dvFrame)) {
        frame.size.height = NSHeight(dvFrame);
    } else {
        NSScrollView *sv = self.enclosingScrollView;
        if (sv) {
            
            NSRect svFrame = sv.frame;
            
            CGFloat newY = round((NSHeight(svFrame) - NSHeight(dvFrame)) * (CGFloat)0.5);
            if (newY != NSMinY(dvFrame)) {
                dvFrame.origin.y = newY;
                _documentView.frame = dvFrame;
            }
            
            frame.size.height = NSHeight(svFrame);
        }
    }
    [super setFrame:frame];
    [self updateIndicatorPosition];
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    [self removeTrackingArea:_trackingArea];
    NSTrackingAreaOptions trackingOptions = NSTrackingActiveInKeyWindow |
                                            NSTrackingMouseEnteredAndExited;
    
    _trackingArea = [[NSTrackingArea alloc] initWithRect:NSInsetRect(_indicatorFrame, -4, 0)
                                                 options:trackingOptions
                                                   owner:self
                                                userInfo:nil];
    [self addTrackingArea:_trackingArea];
}

- (BOOL)isFlipped {
    return NO;
}

- (BOOL)canBecomeKeyView {
    return YES;
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)mouseEntered:(NSEvent *)event {
    _mouseIn = YES;
    [NSCursor pop];
    [[NSCursor resizeLeftRightCursor] push];
}

- (void)mouseExited:(NSEvent *)event {
    _mouseIn = NO;
    [NSCursor pop];
}

- (void)mouseDown:(NSEvent *)event {
    if (_mouseIn) {
        NSApplication *app = [NSApplication sharedApplication];
        NSEventMask eventMask = NSEventMaskLeftMouseUp | NSEventMaskLeftMouseDragged;
        [_delegate timelineViewMouseDown:self];
        
        while (1) {
            event = [app nextEventMatchingMask:eventMask
                                     untilDate:[NSDate distantFuture]
                                        inMode:NSEventTrackingRunLoopMode
                                       dequeue:YES];
            
            switch ([event type]) {
                    
                case NSEventTypeLeftMouseDragged:
                    [self updateIndicatorPositionWithEvent:event];
                    break;
                case NSEventTypeLeftMouseUp:
                    [self mouseUp:event];
                    [self updateTrackingAreas];
                    [_delegate timelineViewMouseUp:self];
                    _mouseIn = NO;
                    return;
                default:
                    break;
            }
        }
    } else if (event.clickCount > 1) {
        [_delegate timelineViewMouseDown:self];
        [self updateIndicatorPositionWithEvent:event];
        [self updateTrackingAreas];
        [_delegate timelineViewMouseUp:self];
    }
    [self.window makeFirstResponder:self];
    [super mouseDown:event];
}

#pragma mark - Methods

static double mousePointToDoubleValue(NSPoint point,
                                      NSRect trackRect,
                                      NSRect indicatorRect,
                                      double maxValue, double minValue) {
    CGFloat position;
    const CGFloat indicatorHalfWidth = NSWidth(indicatorRect) * (CGFloat)0.5;
    
    if (point.x < NSMinX(trackRect) + indicatorHalfWidth) {
        position = NSMinX(trackRect) + indicatorHalfWidth;
    }
    else if (point.x > NSMaxX(trackRect) - indicatorHalfWidth) {
        position = NSMaxX(trackRect) - indicatorHalfWidth;
    }
    else {
        position = point.x;
    }
    
    const CGFloat result = (position - (NSMinX(trackRect) + indicatorHalfWidth))
                          / (NSWidth(trackRect) - NSWidth(indicatorRect));
    
    return result * (maxValue - minValue) + minValue;
}

- (void)updateIndicatorPosition {
    NSSize size = _indicatorFrame.size;
    NSRect trackRect = _workingArea;
    
    CGFloat scale = (_doubleValue - _minValue) / (_maxValue - _minValue);
    
    NSPoint origin = trackRect.origin;
    origin.x += round((NSWidth(trackRect) - size.width) * scale);
    
    _indicatorFrame.origin.x = origin.x;
    _indicatorFrame.size.height = NSHeight(trackRect);
    CGPathRef path = CGPathCreateWithRect(_indicatorFrame, nil);
    _indicatorLayer.path = path;
    CFRelease(path);
}


- (void)updateIndicatorPositionWithEvent:(NSEvent *)event {

    NSPoint local_point = [self convertPoint:event.locationInWindow
                                    fromView:nil];
    self.doubleValue = mousePointToDoubleValue(local_point,
                                               _workingArea, _indicatorFrame,
                                               _maxValue, _minValue);
    [self autoscroll:event];
    [self updateIndicatorPosition];

}

@end
