//
//  SLHPreferences.h
//  Slash
//
//  Created by Terminator on 9/28/18.
//  Copyright © 2018 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/* User-defaults keys */
extern NSString *const SLHPreferencesFFMpegFilePathKey;
extern NSString *const SLHPreferencesFFProbeFilePathKey;
extern NSString *const SLHPreferencesMPVFilePathKey;
extern NSString *const SLHPreferencesRecentOutputPaths;
extern NSString *const SLHPreferencesOutputPathSameAsInput;

@interface SLHPreferences : NSWindowController

+ (instancetype)preferences;

@property (copy) NSString *currentOutputPath;
@property BOOL outputPathSameAsInput;

@property (readonly) NSString *mpvConfigPath;
@property (readonly) NSString *mpvLuaScriptPath;

@property (readonly) NSUInteger numberOfThreads;
@property (readonly) BOOL updateFileName;

@property NSString *ffmpegPath;
@property NSString *ffprobePath;
@property NSString *mpvPath;

@property NSString *lastUsedFormatName;

@end
