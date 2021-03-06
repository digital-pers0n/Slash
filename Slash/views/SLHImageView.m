//
//  SLHImageView.m
//  Slash
//
//  Created by Terminator on 2019/03/27.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHImageView.h"

@implementation SLHImageView

@synthesize delegate = _delegate;

- (BOOL)mouseDownCanMoveWindow  {
    return NO;
}

#pragma mark - NSEvent

- (void)mouseUp:(NSEvent *)theEvent {
    [super mouseUp:theEvent];
    [_delegate imageView:self didUpdateSelection:self.selectionRect];
}

- (void)mouseDragged:(NSEvent *)theEvent {
    [super mouseDragged:theEvent];
    [_delegate imageView:self didUpdateSelection:self.selectionRect];
}

@end
