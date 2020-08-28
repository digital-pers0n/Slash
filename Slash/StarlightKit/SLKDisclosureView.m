//
//  SLKDisclosureView.m
//  Slash
//
//  Created by Terminator on 2020/8/19.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLKDisclosureView.h"
#import "MPVKitDefines.h"

static const CGFloat SLKHeaderViewHeight = 20.0;
static const CGFloat SLKHeaderViewFontSize = 10.0;
static const CGFloat SLKHeaderViewMargin = 7.0;

#pragma mark - **** SLHDisclosureHeaderView ****

@interface SLKDisclosureHeaderView () {
    @package
    NSTextFieldCell *_buttonCell;
    NSRect _buttonFrame;
    NSTrackingArea *_trackingArea;
    BOOL _mouseIn;
    NSTextFieldCell *_titleCell;
    BOOL _closed;
    __unsafe_unretained SLKDisclosureView *_disclosureView;
}

- (void)updateButtonFrame OBJC_DIRECT;
- (BOOL)isMouseIn OBJC_DIRECT;

@end

@implementation SLKDisclosureHeaderView

#pragma mark - Overrides

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _titleCell = [[NSTextFieldCell alloc] initTextCell:@"Empty"];
        _titleCell.bordered = NO;
        _titleCell.font = [NSFont boldSystemFontOfSize:SLKHeaderViewFontSize];
        _buttonCell = [[NSTextFieldCell alloc] initTextCell:@"Hide"];
        _buttonCell.bordered = NO;
        _buttonCell.font = [NSFont boldSystemFontOfSize:SLKHeaderViewFontSize];
        _buttonCell.textColor = [NSColor disabledControlTextColor];
        [self updateButtonFrame];
        _trackingArea = [[NSTrackingArea alloc] init];
    }
    return self;
}

- (BOOL)isFlipped {
    return NO;
}

#pragma mark - Methods

- (void)updateButtonFrame {
    CGFloat width = NSWidth(self.bounds);
    CGFloat cellWidth = _buttonCell.cellSize.width;
    _buttonFrame = NSMakeRect(width - (cellWidth + SLKHeaderViewMargin * 2), 0,
                   cellWidth + SLKHeaderViewMargin * 2, SLKHeaderViewHeight);
}

- (BOOL)isMouseIn {
    NSWindow *window = self.window;
    NSPoint mouseLocation = window.mouseLocationOutsideOfEventStream;
    mouseLocation = [window.contentView convertPoint:mouseLocation toView:self];
    return NSMouseInRect(mouseLocation, self.bounds, /* flipped */ NO);
}

@end // SLKDisclosureHeaderView

#pragma mark - **** SLHDisclosureView ****

@implementation SLKDisclosureView

- (void)drawRect:(NSRect)dirtyRect {
}

@end
