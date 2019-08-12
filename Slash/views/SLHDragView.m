//
//  SLHDragView.m
//  Slash
//
//  Created by Terminator on 2018/07/18.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import "SLHDragView.h"



#pragma mark - FFDragView Class

@interface SLHDragView () {
    BOOL _draggingFeedback;
    NSColor *_feedbackColor;
    NSColor *_feedbackLineColor;
    NSColor *_clearColor;
    NSColor *_backgroundColor;
    NSRect _feedbackFrame;
    NSBezierPath *_feedbackPath;
}

@end

@implementation SLHDragView

#pragma mark - Initialization

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
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
    [self registerForDraggedTypes:@[NSFilenamesPboardType]];
    [NSBezierPath setDefaultLineWidth:0.32];
    _feedbackColor = [NSColor colorWithCalibratedWhite:0.0 alpha:0.04];
    _feedbackLineColor = [NSColor colorWithCalibratedWhite:0.0 alpha:0.48];
    _clearColor = [NSColor clearColor];
    _backgroundColor = [NSColor windowBackgroundColor];
}

#pragma mark - Draw View

- (void)drawRect:(NSRect)dirtyRect {
    if (_draggingFeedback) {
        NSRect bounds = self.bounds;
        [_backgroundColor setFill];
        NSRectFill(bounds);
        [_feedbackColor setFill];
        [_feedbackLineColor setStroke];
        bounds.origin.x += 20;
        bounds.size.width -= 40;
        bounds.origin.y += 16;
        bounds.size.height -= 32;
        _feedbackPath = [NSBezierPath bezierPathWithRoundedRect:bounds xRadius:4 yRadius:4];
        [_feedbackPath fill];
        [_feedbackPath stroke];
    }
}

#pragma mark - Drag Operation

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    
    if ([pboard.types containsObject:NSFilenamesPboardType] && sourceDragMask & NSDragOperationGeneric) {
        _draggingFeedback = YES;
        [self setNeedsDisplay:YES];
        [_delegate didBeginDraggingSession];
        return NSDragOperationGeneric;
    }
    return NSDragOperationNone;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender {
    _draggingFeedback = NO;
    [self setNeedsDisplay:YES];
    [_delegate didEndDraggingSession];
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    BOOL result = NO;
    
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    
    if ([pboard.types containsObject:NSFilenamesPboardType] && sourceDragMask & NSDragOperationGeneric) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        [_delegate didReceiveFilename:files.firstObject];
        result = YES;
    }
    _draggingFeedback = NO;
    [self setNeedsDisplay:YES];
    [_delegate didEndDraggingSession];
    
    
    return result;
}

#pragma mark - Mouse Events

- (void)mouseDown:(NSEvent *)theEvent {
    [super mouseDown:theEvent];
    [_delegate didReceiveMouseEvent:theEvent];
}

- (void)rightMouseDown:(NSEvent *)theEvent {
    [super rightMouseDown:theEvent];
    [_delegate didReceiveMouseEvent:theEvent];
}

@end
