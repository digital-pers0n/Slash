//
//  SLHSeparatorView.m
//  Slash
//
//  Created by Terminator on 2020/02/24.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLHSeparatorView.h"
#define ENABLE_1PIX_SEPARATOR 0


@implementation SLHSeparatorView

- (void)awakeFromNib {
    if (!_color) {
        _color = [NSColor gridColor];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    [_color set];
    NSRect frame;
    
#if ENABLE_1PIX_SEPARATOR
    
    frame = self.frame;
    NSSize cellSize = NSMakeSize(NSWidth(frame), 1);
    
    frame.origin.y = round((NSHeight(frame) - cellSize.height) * (CGFloat)0.5);
    frame.origin.x = round((NSWidth(frame) - cellSize.width) * (CGFloat)0.5);
    frame.size = cellSize;
    
#else
    
    frame = dirtyRect;
    
#endif
    
     [NSBezierPath fillRect:frame];
}

- (BOOL)isOpaque {
    return YES;
}

@end
