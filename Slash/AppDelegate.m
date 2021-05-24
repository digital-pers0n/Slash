//
//  AppDelegate.m
//  Slash
//
//  Created by Terminator on 2018/07/17.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import "AppDelegate.h"
#import "SLTUtils.h"
#import "SLHPreferences.h"
#import "SLHWindowController.h"
#import "MPVPlayerItem.h"
#import "MPVPlayerItemTrack.h"
#import "SLHNumberToStringTransformer.h"

char *g_temp_dir;

@interface AppDelegate ()

@property SLHPreferences *preferences;
@property (nonatomic, weak) IBOutlet SLHWindowController *mainWindowController;

@end

@implementation AppDelegate

+ (void)initialize {
    if (NSAppKitVersionNumber > NSAppKitVersionNumber10_12) {
        NSWindow.allowsAutomaticWindowTabbing = NO;
    }
    [NSValueTransformer setValueTransformer:[SLHNumberToStringTransformer new]
                                    forName:NSStringFromClass([SLHNumberToStringTransformer class])];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSError *error;
    if (!SLTTemporaryDirectoryInit(&error)) {
        NSLog(@"%s: %@",__PRETTY_FUNCTION__, error);
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        [NSApp terminate:nil];
    }
    NSString *tmpDir = SLTTemporaryDirectory();
    g_temp_dir = strdup(tmpDir.UTF8String);

    [_mainWindowController showWindow:self];
    
//    [_mainWindow showWindow:self];
    _preferences = [SLHPreferences preferences];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    free(g_temp_dir);
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

- (void)openDocument:(id)sender {
    NSWindow *window = _mainWindowController.window;
    [window makeKeyAndOrderFront:nil];
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.allowsMultipleSelection = NO;
    
    __unsafe_unretained typeof(self) obj = self;
    
    [openPanel beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
        
        if (result == NSModalResponseOK) {
            NSURL *URL = openPanel.URL;
            if ([obj->_mainWindowController loadFileURL:URL]) {
                [NSDocumentController.sharedDocumentController noteNewRecentDocumentURL:URL];
            }
        }
        
    }];
    openPanel = nil;
}

- (void)newDocument:(id)sender {
    [self openDocument:sender];
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
    SLHWindowController *controller = _mainWindowController;
    [controller.window makeKeyAndOrderFront:nil];
    NSURL * url = [NSURL fileURLWithPath:filename];
    BOOL result = [controller loadFileURL:url];
    if (result) {
        // bump a recently open file up in the "Open Recent" submenu
        [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:url];
    }
    return result;
}

#pragma mark - IBActions

- (IBAction)openPreferences:(id)sender {
    [_preferences showWindow:sender];
}

- (IBAction)revealOutputFile:(id)sender {
    NSWorkspace *sharedWorkspace = [NSWorkspace sharedWorkspace];
    [sharedWorkspace selectFile:_mainWindowController.lastEncodedMediaFilePath inFileViewerRootedAtPath:@""];
}

@end
