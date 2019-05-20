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

char *g_temp_dir;

@interface AppDelegate ()

@property IBOutlet SLHMainWindowController *mainWindow;
@property SLHPreferences *preferences;

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
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    free(g_temp_dir);
}

#pragma mark - IBActions

- (IBAction)openPreferences:(id)sender {
    [_preferences showWindow:sender];
}


@end
