//
//  SLHTabBarView.m
//  Slash
//
//  Created by Terminator on 2018/11/08.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import "SLHTabBarView.h"

static const NSUInteger kNumberOfTabs = 3;

@interface SLHTabBarView () {
    // Colors
    NSColor *_backgroundColor;
    NSColor *_foregroundColor;
    NSColor *_highlightColor;
    NSColor *_strokeColor;
    
    // Font attributes
    NSDictionary *_activeFontAttrs;
    NSDictionary *_inactiveFontAttrs;
    
    // Indices
    NSUInteger _selectedTabIndex;
    NSInteger _highlightedTabIndex;
    
    // Labels
    NSArray <NSString *> *_labels;
    
    // Other
    NSRect *_rects;
    NSTrackingArea *_trackingArea;
}

@end

@implementation SLHTabBarView

#pragma mark - Initialize

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self _setUp];
    }
    return self;
}

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _setUp];
    }
    return self;
}

- (void)_setUp {
    _backgroundColor = [NSColor colorWithDeviceWhite:0.95 alpha:1];
    _foregroundColor = [NSColor colorWithDeviceWhite:0.98 alpha:1];
    _highlightColor = [NSColor colorWithDeviceWhite:1 alpha:1];
    _strokeColor = [NSColor lightGrayColor];
    
    _rects = malloc(sizeof(NSRect) * kNumberOfTabs);
    _selectedTabIndex = 0;
    _highlightedTabIndex = -1;
    
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    [paragraph setLineBreakMode: NSLineBreakByTruncatingTail];
    [paragraph setAlignment:NSTextAlignmentCenter];
    NSUInteger fontSize = 10;
    _activeFontAttrs =  @{
                        NSFontAttributeName:[NSFont systemFontOfSize:fontSize],
                        NSParagraphStyleAttributeName: paragraph,
                        };
    _inactiveFontAttrs = @{
                         NSFontAttributeName:[NSFont systemFontOfSize:fontSize],
                         NSParagraphStyleAttributeName: paragraph,
                         NSForegroundColorAttributeName: [NSColor colorWithDeviceWhite:0.36 alpha:1.0],
                         };
    
    _labels = @[@"Video", @"Audio", @"Filters"];
}

#pragma mark - Draw

static inline void _calcTextFrame(NSRect *cellFrame, CGFloat textHeight) {
    cellFrame->origin.y = (NSHeight(*cellFrame) - textHeight) / 2;
    cellFrame->size.height = textHeight;
    cellFrame->origin.x += 4;
    cellFrame->size.width -= 8;
}

- (void)drawRect:(NSRect)dirtyRect {
    NSRect bounds = self.bounds;
    NSRect viewFrame = bounds;
    CGFloat tabWidth = NSWidth(bounds) / kNumberOfTabs;
    
    if (tabWidth != NSWidth(_rects[0])) { // recalculate tab rects
        bounds.size.width = tabWidth;
        for (int i = 0; i < kNumberOfTabs; i++) {
            bounds.origin.x = tabWidth * i;
            _rects[i] = bounds;
        }
    }
    
    for (int i = 0; i < kNumberOfTabs; i++) {
        
        NSRect cellFrame = _rects[i];
        NSDictionary *attrs;
        if (i == _selectedTabIndex) { // set font attributes and tab color
            [_foregroundColor set];
            attrs = _activeFontAttrs;
        } else {
            if (i == _highlightedTabIndex) {
                [_highlightColor set];
            } else {
                [_backgroundColor set];
            }
            attrs = _inactiveFontAttrs;
        }
        NSRectFill(cellFrame);
        
        /* calculate label frame */
        NSString *label = _labels[i];
        CGFloat textHeight = [label sizeWithAttributes:attrs].height;
        _calcTextFrame(&cellFrame, textHeight);
        [label drawInRect:cellFrame withAttributes:attrs];
    }
    [_strokeColor set];
    NSFrameRect(viewFrame);
}

#pragma mark - Mouse Tracking

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    _trackingArea = [[NSTrackingArea alloc] initWithRect:self.frame
                                                 options:NSTrackingActiveAlways|NSTrackingMouseEnteredAndExited|NSTrackingInVisibleRect|NSTrackingMouseMoved
                                                   owner:self
                                                userInfo:nil];
    [self addTrackingArea:_trackingArea];
}

- (void)mouseMoved:(NSEvent *)event {
    NSPoint event_location = event.locationInWindow;
    NSPoint local_point = [self convertPoint:event_location fromView:nil];
    
    for (int i = 0; i < kNumberOfTabs; i++) {
        if ([self mouse:local_point inRect:_rects[i]]) {
            if (i == _highlightedTabIndex) {    // ignore if already highlighted
                break;
            }
            _highlightedTabIndex = i;
            [self setNeedsDisplay:YES];
            break;
        }
    }
}

- (void)mouseExited:(NSEvent *)event {
    _highlightedTabIndex = -1;
    [self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent *)event {
    NSPoint event_location = event.locationInWindow;
    NSPoint local_point = [self convertPoint:event_location fromView:nil];

    for (int i = 0; i < kNumberOfTabs; i++) {
        if ([self mouse:local_point inRect:_rects[i]]) {
            if (i == _selectedTabIndex) {       // ignore if already selected
                break;
            }
            _selectedTabIndex = i;
            _highlightedTabIndex = -1;
            [self setNeedsDisplay:YES];
            [_delegate tabBarView:self didSelectTabAtIndex:i];
            break;
        }
    }
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event {
    return YES;
}

@end
