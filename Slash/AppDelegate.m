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

static NSString *const _ffmpegPath  = @"/usr/local/bin/ffmpeg1";
static NSString *const _ffprobePath = @"/usr/local/bin/ffprobe";
static NSString *const _mpvPath     = @"/usr/local/bin/mpv1";
static NSString *const _appInitializedKey = @"appInitialized";

extern NSString *const SLHPlayerMPVConfigPath;

@interface AppDelegate ()

@property IBOutlet SLHMainWindowController *mainWindow;
@property SLHPreferences *preferences;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [_mainWindow showWindow:self];
    _preferences = [SLHPreferences preferences];
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    if (![defs boolForKey:_appInitializedKey]) {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSMutableString *missing = [NSMutableString new];
        if ([fm fileExistsAtPath:_ffmpegPath isDirectory:NO]) {
            [defs setObject:_ffmpegPath forKey:SLHPreferencesFFMpegFilePathKey];
        } else {
            [missing appendString:@"ffmpeg\n"];
        }
    
        if ([fm fileExistsAtPath:_ffprobePath isDirectory:NO]) {
            [defs setObject:_ffprobePath forKey:SLHPreferencesFFProbeFilePathKey];
        } else {
            [missing appendString:@"ffprobe\n"];
        }
        
        if ([fm fileExistsAtPath:_mpvPath isDirectory:NO]) {
            [defs setObject:_mpvPath forKey:SLHPreferencesMPVFilePathKey];
        } else {
            [missing appendString:@"mpv\n"];
        }
        
        if (missing.length) {
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = @"Error";
            alert.informativeText =
                    [NSString stringWithFormat:@"Following components are missing:\n\n%@\n"
                                                "Install them in /urs/local/bin/ or set valid paths in preferences", missing];
            [alert runModal];
        } else {
            [defs setBool:YES forKey:_appInitializedKey];
        }
    }
    
    { // Copy resources
    
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *appSupp = [fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject;
        appSupp = [appSupp URLByAppendingPathComponent:@"Slash" isDirectory:YES];
        NSString *path = appSupp.path;
        
        if (![fileManager fileExistsAtPath:path]) {
            
            [fileManager createDirectoryAtURL:appSupp withIntermediateDirectories:NO attributes:nil error:nil];
        }
        
        NSString *mpvConfigPath = [SLHPlayerMPVConfigPath stringByExpandingTildeInPath];
        if (![fileManager fileExistsAtPath:mpvConfigPath isDirectory:NO]) {
            NSString *path = [[NSBundle mainBundle] pathForResource:@"mpv" ofType:@"conf"];
            NSError *error = nil;
            [fileManager copyItemAtPath:path toPath:mpvConfigPath error:&error];
            if (error) {
                NSLog(@"Initialization error: %@", error.localizedDescription);
            }
        }
        
        NSString *luaScriptPath = [@"~/Library/Application Support/Slash/script.lua" stringByExpandingTildeInPath];
        if (![fileManager fileExistsAtPath:luaScriptPath isDirectory:NO]) {
            path = [[NSBundle mainBundle] pathForResource:@"script" ofType:@"lua"];
            NSError *error = nil;
            [fileManager copyItemAtPath:path toPath:luaScriptPath error:&error];
            if (error) {
                NSLog(@"Initialization error: %@", error.localizedDescription);
            }
        }
    }
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

#pragma mark - IBActions

- (IBAction)openPreferences:(id)sender {
    [_preferences showWindow:sender];
}


@end
