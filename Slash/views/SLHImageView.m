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

#pragma mark - NSEvent

- (void)mouseDragged:(NSEvent *)theEvent {
    [super mouseDragged:theEvent];
    [_delegate imageView:self didUpdateSelection:self.selectionRect];
}

@end
