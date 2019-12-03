//
//  SLHEmptyView.m
//  Slash
//
//  Created by Terminator on 2019/12/03.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHEmptyView.h"

@interface SLHEmptyView () {
    NSTextFieldCell *_textCell;
    NSSize _cellSize;
}

@end

@implementation SLHEmptyView

#pragma mark - Initialization

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setUp];
    }
    return self;
}

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUp];
    }
    return self;
}

- (void)setUp {
    _textCell = [[NSTextFieldCell alloc] initTextCell:@""];
    _textCell.bordered = NO;
    _textCell.font = [NSFont systemFontOfSize:20];;
    _textCell.textColor = [[NSColor disabledControlTextColor] colorWithAlphaComponent:0.5];
    _cellSize = _textCell.cellSize;
}

#pragma mark - Properties

- (void)setStringValue:(NSString *)stringValue {
    _textCell.stringValue = stringValue;
    _cellSize = _textCell.cellSize;
}

- (NSString *)stringValue {
    return _textCell.stringValue;
}

- (void)setFont:(NSFont *)font {
    _textCell.font = font;
    _cellSize = _textCell.cellSize;
}

- (NSFont *)font {
    return _textCell.font;
}

- (void)setTextColor:(NSColor *)textColor {
    _textCell.textColor = textColor;
}

- (NSColor *)textColor {
    return _textCell.textColor;
}

#pragma mark - Overrides

- (void)drawRect:(NSRect)dirtyRect {
    NSRect frame = self.frame;
    NSSize cellSize = _cellSize;
    
    frame.origin.y = round((NSHeight(frame) - cellSize.height) * (CGFloat)0.5);
    frame.origin.x = round((NSWidth(frame) - cellSize.width) * (CGFloat)0.5);
    frame.size = cellSize;
    
    [_textCell drawWithFrame:frame inView:self];
}

- (void)viewWillMoveToSuperview:(NSView *)newSuperview {
    if (newSuperview) {
        NSRect frame = newSuperview.frame;
        frame.origin = NSZeroPoint;
        self.frame = frame;
    }
    [super viewWillMoveToSuperview:newSuperview];
}

@end
