//
//  SLHPreferences.h
//  Slash
//
//  Created by Terminator on 9/28/18.
//  Copyright © 2018 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLHPreferences : NSWindowController

+ (instancetype)preferences;

@property (readonly) NSString *appSupportPath;

@property (copy) NSString *currentOutputPath;
@property BOOL outputPathSameAsInput;

@property (readonly) NSString *mpvConfigPath;
@property (readonly) NSString *mpvLuaScriptPath;

@property (readonly) NSUInteger numberOfThreads;
@property (readonly) BOOL updateFileName;

@property (null_resettable) NSString *ffmpegPath;
@property (null_resettable) NSString *mpvPath;

@property (nonatomic) BOOL hasFFmpeg;
@property (nonatomic) BOOL hasMPV;

@property NSString *lastUsedFormatName;

@property (null_resettable) NSString *screenshotPath;
@property (null_resettable) NSString *screenshotTemplate;
@property NSString *screenshotFormat;
@property NSInteger screenshotJPGQuality;
@property NSInteger screenshotPNGCompression;

@property (nonatomic, null_resettable) NSString *osdFontName;
@property (nonatomic) NSInteger osdFontSize;
@property (nonatomic) BOOL osdFontScaleByWindow;
@property (nonatomic, null_resettable) NSString *subtitlesFontName;
@property (nonatomic) NSInteger subtitlesFontSize;
@property (nonatomic) BOOL subtitlesFontScaleByWindow;

@property (readonly) NSDictionary *advancedOptions;
@property (nonatomic) BOOL enableAdvancedOptions;
/** Use the valueForKey: method with the @"key" or @"value" argument to access underlying data */
@property (nonatomic, readonly) id lastEditedAdvancedOption;

@property (nonatomic) NSWindowTitleVisibility windowTitleStyle;

@property (nonatomic) BOOL useHiResOpenGLSurface;
@property (nonatomic) BOOL pausePlaybackDuringWindowResize;

@property (nonatomic) BOOL trimViewShouldGeneratePreviewImages;
@property (nonatomic) double trimViewVerticalZoom;
@property (nonatomic) double trimViewHorizontalZoom;

@property (nonatomic) BOOL shouldOverwriteFiles;

@property (nonatomic, null_resettable) NSString * outputNameTemplate;
@property (nonatomic) BOOL enableOutputNameTemplate;

@end

NS_ASSUME_NONNULL_END
