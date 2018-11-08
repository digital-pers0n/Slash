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
    _strokeColor = [NSColor darkGrayColor];
    
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
    
    _labels = @[@"Video", @"Audio", @"Effects"];
}


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
