//
//  SLHVideoSlider.m
//  Slash
//
//  Created by Terminator on 2020/01/27.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLHVideoSlider.h"
#import "SLHTimeFormatter.h"
#import <QuartzCore/QuartzCore.h>

#define SLHToolTipWidth 120

@interface SLHVideoSlider () {
    NSTrackingArea *_trackingArea;
    NSWindow *_toolTipWindow;
    dispatch_source_t _timer;
    CATextLayer *_textLayer;
}

@end

@implementation SLHVideoSlider

#pragma mark - Overrides

- (void)awakeFromNib {
    _trackingArea = [NSTrackingArea new];
    NSRect toolTipFrame = NSMakeRect(0, 0, SLHToolTipWidth, 15);
    _toolTipWindow = [[NSWindow alloc] initWithContentRect: toolTipFrame
                                           styleMask: NSWindowStyleMaskBorderless
                                             backing: NSBackingStoreBuffered
                                               defer: YES];
    
    _textLayer = [CATextLayer new];
    _textLayer.font = (__bridge CFTypeRef _Nullable)([NSFont fontWithName:@"Osaka" size:10]);
    _textLayer.fontSize = 11;
    _textLayer.alignmentMode = kCAAlignmentCenter;
    _textLayer.foregroundColor = [NSColor controlTextColor].CGColor;
    _textLayer.backgroundColor = [NSColor windowBackgroundColor].CGColor;
    _toolTipWindow.contentView.layer = _textLayer;
    _toolTipWindow.contentView.wantsLayer = YES;
    _toolTipWindow.hasShadow = YES;
    _toolTipWindow.collectionBehavior =  NSWindowCollectionBehaviorFullScreenAuxiliary | NSWindowCollectionBehaviorTransient;
    _toolTipWindow.level = kCGMaximumWindowLevelKey;
}

- (void)createTimerWithInterval:(double)seconds {
    if (_timer) {
        dispatch_cancel(_timer);
    }
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_set_context(_timer, (__bridge void*)self);
    dispatch_source_set_timer(_timer, dispatch_time(DISPATCH_TIME_NOW, 4 * NSEC_PER_SEC), seconds * NSEC_PER_SEC, 10 * NSEC_PER_SEC);
    dispatch_source_set_event_handler_f(_timer, &timer_handler);
    dispatch_resume(_timer);
}

static void timer_handler(void *ctx) {
    __unsafe_unretained SLHVideoSlider *obj = (__bridge typeof(obj))ctx;
    [obj closeToolTip];
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    [self removeTrackingArea:_trackingArea];

    _trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect
                                                 options:
                     NSTrackingInVisibleRect | NSTrackingActiveInKeyWindow |
                     NSTrackingMouseMoved    | NSTrackingMouseEnteredAndExited
                                                   owner:self
                                                userInfo:nil];
    [self addTrackingArea:_trackingArea];
}

- (void)mouseMoved:(NSEvent *)event {
    double maxValue =  self.maxValue;
    if (maxValue > 0 && (event.modifierFlags & NSEventModifierFlagOption)) {
        NSRect viewFrame = self.frame;
        NSPoint event_location = event.locationInWindow;
        NSPoint local_point = [self convertPoint:event_location fromView:nil];
        double value = (local_point.x / (NSWidth(viewFrame)) * maxValue);
        _textLayer.string = SLHTimeFormatterStringForDoubleValue(value);
        NSWindow *w = _toolTipWindow;
        NSPoint global_point = [NSEvent mouseLocation];

        global_point.x -= (SLHToolTipWidth * (CGFloat)0.5);
        global_point.y += (NSHeight(viewFrame) - local_point.y + 1);

        [w setFrameOrigin:global_point];
        
        if (!_timer) {
            [w orderFront:nil];
            [self createTimerWithInterval:5.0];
        }

    }
}

- (void)scrollWheel:(NSEvent *)event {
    if (self.enabled) {
        [_delegate videoSlider:self scrollWheelDeltaY:event.scrollingDeltaY];
    }
}

- (void)mouseExited:(NSEvent *)event {
    [self closeToolTip];
    [super mouseExited:event];
}

- (void)mouseDown:(NSEvent *)event {
    [self closeToolTip];
    [super mouseDown:event];
}

- (BOOL)isFlipped {
    return NO;
}

#pragma mark - Methods

- (void)closeToolTip {
    if (_timer) {
        dispatch_cancel(_timer);
        _timer = nil;
        [_toolTipWindow orderOut:nil];
    }
}

@end
