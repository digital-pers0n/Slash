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
extern NSString *const SLHPreferencesMPVFilePathKey;
extern NSString *const SLHPreferencesRecentOutputPaths;
extern NSString *const SLHPreferencesOutputPathSameAsInput;

@interface SLHPreferences : NSWindowController

+ (instancetype)preferences;

@property (readonly) NSString *appSupportPath;

@property (copy) NSString *currentOutputPath;
@property BOOL outputPathSameAsInput;

@property (readonly) NSString *mpvConfigPath;
@property (readonly) NSString *mpvLuaScriptPath;

@property (readonly) NSUInteger numberOfThreads;
@property (readonly) BOOL updateFileName;

@property NSString *ffmpegPath;
@property NSString *mpvPath;

@property (nonatomic) BOOL hasFFmpeg;
@property (nonatomic) BOOL hasMPV;

@property NSString *lastUsedFormatName;

@property NSString *screenshotPath;
@property NSString *screenshotTemplate;
@property NSString *screenshotFormat;
@property NSInteger screenshotJPGQuality;
@property NSInteger screenshotPNGCompression;

@property (nonatomic) NSString *osdFontName;
@property (nonatomic) NSInteger osdFontSize;
@property (nonatomic) BOOL osdFontScaleByWindow;
@property (nonatomic) NSString *subtitlesFontName;
@property (nonatomic) NSInteger subtitlesFontSize;
@property (nonatomic) BOOL subtitlesFontScaleByWindow;

@property (readonly) NSDictionary *advancedOptions;
@property (nonatomic) BOOL enableAdvancedOptions;
/** Use the valueForKey: method with the @"key" or @"value" argument to access underlying data */
@property (nonatomic, readonly) id lastEditedAdvancedOption;

@end
