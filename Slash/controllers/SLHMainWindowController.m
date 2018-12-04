//
//  SLHMainWindowController.m
//  Slash
//
//  Created by Terminator on 2018/11/14.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import "SLHMainWindowController.h"
#import "SLHDragView.h"
#import "SLHEncoderSettings.h"

@interface SLHMainWindowController () <SLHDragViewDelegate> {
    SLHDragView *_dragView;
    SLHEncoderSettings *_encoderSettings;
    IBOutlet NSView *_customView;
    IBOutlet NSArrayController *_arrayController;
    IBOutlet NSTableView *_tableView;
    
}

@end

@implementation SLHMainWindowController

- (NSString *)windowNibName {
    return self.className;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    /* SLHDragView */
    _dragView = [[SLHDragView alloc] init];
    _dragView.delegate = self;
    _dragView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    _dragView.frame = self.window.contentView.frame;
    [self.window.contentView addSubview:_dragView];
    
    /* SLHEncoderSettings */
    _encoderSettings = [[SLHEncoderSettings alloc] init];
    _encoderSettings.view.frame = _customView.frame;
    _encoderSettings.view.autoresizingMask = _customView.autoresizingMask;
    [_customView.superview replaceSubview:_customView with:_encoderSettings.view];
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
