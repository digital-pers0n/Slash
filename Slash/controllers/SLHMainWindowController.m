//
//  SLHMainWindowController.m
//  Slash
//
//  Created by Terminator on 2018/11/14.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import "SLHMainWindowController.h"
#import "SLHDragView.h"

@interface SLHMainWindowController () <SLHDragViewDelegate> {
    SLHDragView *_dragView;
}

@end

@implementation SLHMainWindowController

- (NSString *)windowNibName {
    return self.className;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    _dragView = [[SLHDragView alloc] init];
    _dragView.delegate = self;
    _dragView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    _dragView.frame = self.window.contentView.frame;
    
    [self.window.contentView addSubview:_dragView];
}

#pragma mark - SLHDragView Delegate

- (void)didReceiveFilename:(NSString *)filename {
    
}
- (void)didBeginDraggingSession {
    
}
- (void)didEndDraggingSession {
    
}
- (void)didReceiveMouseEvent:(NSEvent *)event {
    
}

@end
