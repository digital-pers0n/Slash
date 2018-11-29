//
//  AppDelegate.m
//  Slash
//
//  Created by Terminator on 2018/07/17.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import "AppDelegate.h"
#import "SLHMainWindowController.h"

@interface AppDelegate ()

@property IBOutlet SLHMainWindowController *mainWindow;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [_mainWindow showWindow:self];
    // Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
