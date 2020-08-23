//
//  SLKSeparatorView.m
//  Slash
//
//  Created by Terminator on 2020/8/17.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLKSeparatorView.h"
#import "MPVKitDefines.h"

@interface SLKSeparatorView ()
- (void)commonInit OBJC_DIRECT;
@end

@implementation SLKSeparatorView

#pragma mark - Overrides

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)updateLayer {
    self.layer.backgroundColor = NSColor.gridColor.CGColor;
}

- (BOOL)isOpaque {
    return YES;
}

#pragma mark - Methods

- (void)commonInit {
    self.wantsLayer = YES;
    CALayer *layer = self.layer;
    layer.opaque = YES;
    layer.backgroundColor = NSColor.gridColor.CGColor;
}

@end
