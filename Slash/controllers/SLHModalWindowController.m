//
//  SLHModalWindowController.m
//  Slash
//
//  Created by Terminator on 2019/05/15.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHModalWindowController.h"

@interface SLHModalWindowController () <NSWindowDelegate>

@end

@implementation SLHModalWindowController

#pragma mark - Initialization

- (NSString *)windowNibName {
    return self.className;
}

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
    _title = @"";
    _contentView = [NSView new];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

#pragma mark - Methods

- (void)runModal {
    NSWindow *window = self.window;
    window.contentView = _contentView;
    window.title = _title;
    [window center];
    [NSApp runModalForWindow:window];
}

#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification {
    [_contentView removeFromSuperview];
    [NSApp stopModal];
}

@end
