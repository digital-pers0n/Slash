//
//  AppDelegate.m
//  Slash
//
//  Created by Terminator on 2018/07/17.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import "AppDelegate.h"
#import "SLHMainWindowController.h"
#import "SLHPreferences.h"
#import "SLHMediaItem.h"
#import "SLHWindowController.h"
#import "MPVPlayerItem.h"
#import "MPVPlayerItemTrack.h"

char *g_temp_dir;

@interface AppDelegate ()

@property IBOutlet SLHMainWindowController *mainWindow;
@property SLHPreferences *preferences;
@property (nonatomic, weak) IBOutlet SLHWindowController *mainWindowController;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSString *tmpDir = NSTemporaryDirectory();
    if (tmpDir) {
        tmpDir = [tmpDir stringByAppendingPathComponent:NSBundle.mainBundle.bundleIdentifier];
    } else {
        tmpDir = [NSString stringWithFormat:@"/tmp/%@", NSBundle.mainBundle.bundleIdentifier];
    }
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:tmpDir isDirectory:0]) {
        NSError *error = nil;
        [fm createDirectoryAtPath:tmpDir withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"Initialization Error : %@", error.localizedDescription);
            NSAlert *alert = [NSAlert alertWithError:error];
            [alert runModal];
            [NSApp terminate:self];
        }
    }
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
        
        if (result == NSOKButton) {
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
    [_mainWindowController.window makeKeyAndOrderFront:nil];
    return [_mainWindowController loadFileURL:[NSURL fileURLWithPath:filename]];;
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
