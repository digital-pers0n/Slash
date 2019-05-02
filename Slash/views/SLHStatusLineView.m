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
    NSFont *font =  [NSFont monospacedDigitSystemFontOfSize:11 weight:NSFontWeightRegular];
    _textAttributes =  @{ NSFontAttributeName : font };
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect {
    [_string drawInRect:dirtyRect withAttributes:_textAttributes];
}

#pragma mark - Properties

- (void)setString:(NSString *)string {
    _string = string;
    [self setNeedsDisplay:YES];
}

- (NSString *)string {
    return _string;
}

@end
