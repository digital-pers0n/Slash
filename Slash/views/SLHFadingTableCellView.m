//
//  SLHFadingTableCellView.m
//  Slash
//
//  Created by Terminator on 2020/02/16.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLHFadingTableCellView.h"

@interface SLHFadingTableCellView () {
    NSTrackingArea *_trackingArea;
}
@end

@implementation SLHFadingTableCellView

- (void)awakeFromNib {
    _trackingArea = [NSTrackingArea new];
    NSButton *fadingButton = _fadingButton;
    fadingButton.alphaValue = 0.0;
    fadingButton.wantsLayer = YES;
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    [self removeTrackingArea:_trackingArea];
    
    _trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect
                                                 options:
                     NSTrackingInVisibleRect |
                     NSTrackingActiveInKeyWindow |
                     NSTrackingMouseEnteredAndExited
                                                   owner:self
                                                userInfo:nil];
    [self addTrackingArea:_trackingArea];
}

- (void)mouseEntered:(NSEvent *)event {
    _fadingButton.animator.alphaValue = 1.0;
}

- (void)mouseExited:(NSEvent *)event {
    _fadingButton.animator.alphaValue = 0.0;
}

@end
