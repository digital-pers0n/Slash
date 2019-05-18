//
//  SLHLogController.m
//  Slash
//
//  Created by Terminator on 2019/05/10.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHLogController.h"

@interface SLHLogController () <NSWindowDelegate> {
    NSString *_log;
    IBOutlet NSTextView *_textView;
}

@end

@implementation SLHLogController

- (NSString *)windowNibName {
    return self.className;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

#pragma mark - Methods

- (void)runModal {
    NSWindow *window = self.window;
    [_textView scrollToEndOfDocument:nil];
    [window center];
    [NSApp runModalForWindow:window];
}

#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification {
    [NSApp stopModal];
}

@end
