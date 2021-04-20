//
//  SLHTabBarView.m
//  Slash
//
//  Created by Terminator on 2018/11/08.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import "SLHTabBarView.h"

static const NSUInteger kNumberOfTabs = 5;

@interface SLHTabBarView () {
    
    // Indices
    NSUInteger _selectedTabIndex;
    NSUInteger _highlightedTabIndex;
    
    // Tabs
    NSArray <NSImage *> *_icons;
    NSArray <NSString *> *_toolTips;
    NSButtonCell *_tabCell;
    
    // Other
    NSRect _rects[kNumberOfTabs];
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
    _trackingArea = [NSTrackingArea new];   // dummy tracking area to avoid if() check in the updateTrackingAreas method
    _selectedTabIndex = 0;
    _highlightedTabIndex = NSUIntegerMax;
    
    _icons = @[
               [NSImage imageNamed:@"SLHImageNameVideoTemplate"],
               [NSImage imageNamed:@"SLHImageNameAudioTemplate"],
               [NSImage imageNamed:@"SLHImageNameFiltersTemplate"],
               [NSImage imageNamed:@"SLHImageNameInfoTemplate"],
               [NSImage imageNamed:@"SLHImageNameMetadataTemplate"],
               ];
    
    _toolTips = @[
                  @"Show Video parameters",
                  @"Show Audio parameters",
                  @"Show Filters parameters",
                  @"Show File information",
                  @"Show Metadata Editor"
                ];
    
    assert(_icons.count == kNumberOfTabs && _toolTips.count == kNumberOfTabs);
    
    _tabCell = [[NSButtonCell alloc] init];
    _tabCell.bordered = NO;
    [_tabCell setButtonType:NSButtonTypeToggle];
}

- (void)setSelectedTabIndex:(NSUInteger)selectedTabIndex {
    if (selectedTabIndex < kNumberOfTabs) {
        _selectedTabIndex = selectedTabIndex;
        [_delegate tabBarView:self didSelectTabAtIndex:selectedTabIndex];
        self.needsDisplay = YES;
    }
}

#pragma mark - Overrides

- (void)setFrame:(NSRect)frame {
    
    CGFloat tabWidth = NSWidth(frame) / kNumberOfTabs;
    
    NSRect tabFrame = NSMakeRect(0, 0, tabWidth, NSHeight(frame));
    for (NSUInteger i = 0; i < kNumberOfTabs; i++) {
        tabFrame.origin.x = tabWidth * i;
        _rects[i] = tabFrame;
    }
    [super setFrame:frame];
}

#pragma mark - Draw

- (void)drawRect:(NSRect)dirtyRect {

    NSUInteger idx = 0;
    for (NSImage *icon in _icons) {
        
        _tabCell.image = icon;
        
        if (_selectedTabIndex == idx) {
            _tabCell.state = NSControlStateValueOn;
            [_tabCell drawWithFrame:_rects[idx++] inView:self];
            _tabCell.state = NSControlStateValueOff;
            continue;
        }
        
        if (_highlightedTabIndex == idx) {
            _tabCell.highlighted  = YES;
            [_tabCell drawWithFrame:_rects[idx++] inView:self];
            _tabCell.highlighted = NO;
            continue;
        }
        
        [_tabCell drawWithFrame:_rects[idx++] inView:self];
    }
}



#pragma mark - Mouse Tracking

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    [self removeTrackingArea:_trackingArea];
    _trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect
                                                 options:NSTrackingActiveAlways|NSTrackingMouseEnteredAndExited|NSTrackingInVisibleRect|NSTrackingMouseMoved
                                                   owner:self
                                                userInfo:nil];
    [self addTrackingArea:_trackingArea];
}

- (void)mouseMoved:(NSEvent *)event {
    NSPoint event_location = event.locationInWindow;
    NSPoint local_point = [self convertPoint:event_location fromView:nil];
    
    for (NSUInteger i = 0; i < kNumberOfTabs; i++) {
        if ([self mouse:local_point inRect:_rects[i]]) {
            self.toolTip = nil;
            self.toolTip = _toolTips[i];
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
    _highlightedTabIndex = NSUIntegerMax;
    [self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent *)event {
    NSPoint event_location = event.locationInWindow;
    NSPoint local_point = [self convertPoint:event_location fromView:nil];

    for (NSUInteger i = 0; i < kNumberOfTabs; i++) {
        if ([self mouse:local_point inRect:_rects[i]]) {
            if (i == _selectedTabIndex) {       // ignore if already selected
                break;
            }
            
            NSWindow *window = self.window;
            if (![window makeFirstResponder:window]) {
                NSBeep();
                return;
            }
            _selectedTabIndex = i;
            _highlightedTabIndex = NSUIntegerMax;
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
