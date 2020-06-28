//
//  SLHStatusLineView.m
//  Slash
//
//  Created by Terminator on 2019/05/02.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHStatusLineView.h"

@interface SLHStatusLineView () {
    NSString *_string;
    NSDictionary *_textAttributes;
}

@end

@implementation SLHStatusLineView

#pragma mark - Initialization

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self _setUp];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self _setUp];
    }
    return self;
}

- (void)_setUp {
    _string = @"";
    NSFont *font =  [NSFont monospacedDigitSystemFontOfSize:12 weight:NSFontWeightRegular];
    NSColor *color = [NSColor controlTextColor];
    _textAttributes =  @{
                         NSFontAttributeName              : font,
                         NSForegroundColorAttributeName   : color,
                         };
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect {
    [_string drawInRect:dirtyRect withAttributes:_textAttributes];
}

- (BOOL)wantsDefaultClipping {
    return NO;
}

#pragma mark - Properties

- (void)setString:(NSString *)string {
    _string = string;
    self.needsDisplay = YES;
}

- (NSString *)string {
    return _string;
}

@end
