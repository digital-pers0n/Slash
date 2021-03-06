//
//  SLHWindowController.m
//  Slash
//
//  Created by Terminator on 2019/09/01.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHWindowController.h"
#import "SLHPlayerView.h"
#import "SLHEncoderItem.h"
#import "SLHEncoderItemOptions.h"
#import "SLHEncoderSettings.h"
#import "SLHPreferences.h"
#import "SLHPreferencesKeys.h"
#import "SLHTextEditor.h"
#import "SLHEncoder.h"
#import "SLHModalWindowController.h"
#import "SLHArgumentsViewController.h"
#import "SLHLogController.h"
#import "SLHPresetManager.h"
#import "SLHEncoderQueue.h"
#import "SLHPlayerViewController.h"
#import "SLHEncoderHistory.h"
#import "SLHBitrateFormatter.h"
#import "SLHTrimViewController.h"
#import "SLHTrimViewSettings.h"
#import "SLHOutputNameController.h"
#import "SLHTemplateNameFormatter.h"

#import "SLTObserver.h"
#import "SLTRemotePlayer.h"
#import "SLTUtils.h"

#import "SLKFFmpegInfoController.h"

#import "MPVPlayer.h"
#import "MPVPlayerItem.h"
#import "MPVPlayerItemTrack.h"
#import "MPVPlayerProperties.h"
#import "MPVPlayerCommands.h"

#import "NSMenuItem+SLKAdditions.h"
#import "NSNotificationCenter+SLTAdditions.h"

#import "SLHEncoderVP9Format.h"
#import "SLHEncoderVPXFormat.h"
#import "SLHEncoderX264Format.h"
#import "SLHEncoderUniversalFormat.h"

extern NSString *const SLHEncoderFormatDidChangeNotification;

@interface SLHWindowController () <NSSplitViewDelegate, NSWindowDelegate, NSDraggingDestination, NSTableViewDelegate, NSMenuDelegate, SLHPresetManagerDelegate> {
    IBOutlet SLHPlayerView *_playerView;
    IBOutlet NSView *_sbView;
    IBOutlet NSView *_bottomBarView;
    IBOutlet NSArrayController *_itemsArrayController;
    IBOutlet NSArrayController *_formatsArrayController;
    IBOutlet NSSplitView *_inspectorSplitView;
    IBOutlet NSSplitView *_videoSplitView;
    IBOutlet NSSplitView *_trimSplitView;
    IBOutlet NSView *_trimView;
    IBOutlet NSView *_encoderItemsView;
    IBOutlet NSView *_outputNameView;
    
    IBOutlet NSPopUpButton *_videoStreamPopUp;
    IBOutlet NSPopUpButton *_audioStreamPopUp;
    IBOutlet NSPopUpButton *_subtitlesStreamPopUp;
    IBOutlet NSPopUpButton *_formatsPopUp;
    
    IBOutlet NSTextField *_inputFileInfoTextField;
    
    MPVPlayer *_player;
    SLHPresetManager *_presetManager;
    NSArray <NSMenuItem *> *_defaultPresetMenuItems;
    SLHEncoderSettings *_encoderSettings;
    NSView *_encoderSettingsView;
    SLHEncoder *_encoder;
    SLHTextEditor *_textEditor;
    SLHEncoderHistory *_encoderHistory;
    SLHTrimViewController *_trimViewController;
    NSPopover *_trimViewSettingsPopover;
    SLHOutputNameController *_outputNameController;
    SLHTemplateNameFormatter *_templateNameFormatter;
    NSArray<SLTObserver *> *_prefsObservers;
    
    CGFloat _sideBarWidth;
    CGFloat _bottomBarHeight;
    CGFloat _encoderItemsViewWidth;

}

@property (nonatomic, nullable, weak) SLHEncoderItem *currentEncoderItem;
@property (nonatomic, nullable) NSString *lastEncodedMediaFilePath;
@property (nonatomic, nullable) SLHPreferences *preferences;
@property (nonatomic) SLHTrimViewController * trimViewController;

@end

@implementation SLHWindowController

- (NSString *)windowNibName {
    return self.className;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    /* SLHPresetManager */
    _presetManager = [[SLHPresetManager alloc] init];
    _presetManager.delegate = self;
    [self createDefaultPresetMenuItems];
    
    /* SLHEncoder */
    _encoder = [[SLHEncoder alloc] init];
    
    /* SLHEncoderQueue */
    _queue = [[SLHEncoderQueue alloc] init];
    
    /* SLHEncoderSettings */
    _encoderSettings = [[SLHEncoderSettings alloc] init];
    NSView *view = _encoderSettings.view;
    _encoderSettingsView = view;
    view.autoresizingMask = _sbView.autoresizingMask;
    view.frame = _sbView.frame;
    
    if ([_inspectorSplitView isSubviewCollapsed:_sbView]) {
        view.hidden = YES;
    }
    
    [_sbView.superview replaceSubview:_sbView with:view];
    _videoSplitView.delegate = self;
    _inspectorSplitView.delegate = self;
    
    _sideBarWidth = NSWidth(_sbView.frame);
    _bottomBarHeight = NSHeight(_bottomBarView.frame);
    self.window.delegate = self;
    
    /* SLHFormat */
    SLHEncoderX264Format *x264Fmt = [[SLHEncoderX264Format alloc] init];
    SLHEncoderVPXFormat *vpxFmt = [[SLHEncoderVPXFormat alloc] init];
    SLHEncoderVP9Format *vp9Fmt = [[SLHEncoderVP9Format alloc] init];
    SLHEncoderUniversalFormat *uniFmt = [[SLHEncoderUniversalFormat alloc] init];
    
    NSArray *_formats = @[x264Fmt, vpxFmt, vp9Fmt, uniFmt];
    [_formatsArrayController addObjects:_formats];
    
    SLHPreferences *appPrefs = SLHPreferences.preferences;
    self.preferences = appPrefs;
    
    NSString *name = appPrefs.lastUsedFormatName;
    if (name) {
        [_formatsPopUp selectItemWithTitle:name];
    }
    
    [self formatsPopUpAction:_formatsPopUp];
    
    /* Drag and Drop support */
    [self.window registerForDraggedTypes:@[kSLTTypeFileURL]];
    
    /* MPVPlayer */
    MPVPlayer *player;
    if (appPrefs.enableAdvancedOptions) {
            NSDictionary *options = appPrefs.advancedOptions;
            __unsafe_unretained typeof(self) uSelf = self;

            player = [[MPVPlayer alloc] initWithBlock:^(__weak MPVPlayer *p){
                
                [options enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key,
                                                             id  _Nonnull obj,
                                                             BOOL * _Nonnull stop) {
                    NSError *error = nil;
                    if (![p setString:obj
                          forProperty:key
                                error:&error]) {
                        
                        [uSelf presentError:error];
                    }
                }];
                
            }];
    } else {
        player = [[MPVPlayer alloc] init];
    }
    [player pause];
    _playerView.player = player;
    _player = player;
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(playerDidLoadFile:) name:MPVPlayerDidLoadFileNotification object:player];
    
    SLHPlayerViewController *playerController = _playerView.viewController;
    [nc addObserver:self selector:@selector(playerViewControllerDidChangeInMark:) name:SLHPlayerViewControllerDidChangeInMarkNotification object:playerController];
    [nc addObserver:self selector:@selector(playerViewControllerDidChangeOutMark:) name:SLHPlayerViewControllerDidChangeOutMarkNotification object:playerController];
    [nc addObserver:self selector:@selector(playerViewControllerDidCommitInOutMarks:) name:SLHPlayerViewControllerDidCommitInOutMarksNotification object:playerController];
    
    /* SLHPreferences */
    
    
    [player setString:appPrefs.screenshotTemplate
          forProperty:MPVPlayerPropertyScreenshotTemplate];
    
    [player setString:appPrefs.screenshotPath
          forProperty:MPVPlayerPropertyScreenshotDirectory];
    
    [player setString:appPrefs.screenshotFormat
          forProperty:MPVPlayerPropertyScreenshotFormat];
    
    [player setInteger:appPrefs.screenshotJPGQuality
           forProperty:MPVPlayerPropertyScreenshotJPGQuality];
    
    [player setInteger:appPrefs.screenshotPNGCompression
           forProperty:MPVPlayerPropertyScreenshotPNGCompression];
    
    [player setString:appPrefs.osdFontName
          forProperty:MPVPlayerPropertyOSDFontName];
    
    [player setInteger:appPrefs.osdFontSize
           forProperty:MPVPlayerPropertyOSDFontSize];
    
    [player setBool:appPrefs.osdFontScaleByWindow
        forProperty:MPVPlayerPropertyOSDFontScaleByWindow];
    
    [player setString:appPrefs.subtitlesFontName
          forProperty:MPVPlayerPropertySubsFontName];
    
    [player setInteger:appPrefs.subtitlesFontSize
           forProperty:MPVPlayerPropertySubsFontSize];
    
    [player setBool:appPrefs.subtitlesFontScaleByWindow
        forProperty:MPVPlayerPropertySubsFontScaleByWindow];
    
    self.window.titleVisibility = appPrefs.windowTitleStyle;
    
    [self observePreferences:appPrefs];
    
    /* SLTRemotePlayer */
    SLTRemotePlayer *p = SLTRemotePlayer.sharedInstance;
    p.mpvPath = appPrefs.mpvPath;
    p.mpvConfigPath = appPrefs.mpvConfigPath;
    
    /* SLKFFmpegInfoController */
    if (appPrefs.hasFFmpeg) {
        [SLKFFmpegInfoController.sharedInstance
         updateInfoWithPath:appPrefs.ffmpegPath];
    }
    
    /* SLHEncoderHistory */
    _encoderHistory = [[SLHEncoderHistory alloc] init];
    
    /* SLHTrimViewController */
    self.trimViewController = [[SLHTrimViewController alloc] init];
    NSView *tView = _trimViewController.view;
    tView.frame = _trimView.frame;
    tView.autoresizingMask = _trimView.autoresizingMask;
    [_trimView.superview replaceSubview:_trimView
                                   with:tView];
    _trimView = tView;
    _trimViewController.player = _player;
    _trimViewController.itemsArrayController = _itemsArrayController;
    
    /* SLHTrimViewSettings */
    SLHTrimViewSettings * trimViewSettings = [[SLHTrimViewSettings alloc] init];
    trimViewSettings.controller = _trimViewController;
    _trimViewSettingsPopover = [[NSPopover alloc] init];
    _trimViewSettingsPopover.contentViewController = trimViewSettings;
    _trimViewSettingsPopover.behavior = NSPopoverBehaviorTransient;
    
    /* SLHOutputNameController */
    _outputNameController = [[SLHOutputNameController alloc] init];
    NSView *onView = _outputNameController.view;
    onView.frame = _outputNameView.frame;
    onView.autoresizingMask = _outputNameView.autoresizingMask;
    [_outputNameView.superview replaceSubview:_outputNameView with:onView];
    _outputNameView = onView;
    _outputNameController.encoderItemsArrayController = _itemsArrayController;
    
    if (!appPrefs.enableOutputNameTemplate) {
        _outputNameController.nameEditable = YES;
    }
    
    /* SLHTemplateNameFormatter */
    _templateNameFormatter = [[SLHTemplateNameFormatter alloc] init];
    _templateNameFormatter.templateFormat = _preferences.outputNameTemplate;
    
    /* NSApplication */
    [nc addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:NSApp];
}

#pragma mark - Methods

- (NSString *)outputNameForDocument:(SLHEncoderItem *)document {
    NSString *extension = document.outputPath.pathExtension;
    if (!extension) {
        extension = document.playerItem.url.pathExtension;
        if (!extension) {
            extension = @"";
        }
    }
    NSString *newName = [_templateNameFormatter stringFromDocument:document];
    return [newName stringByAppendingPathExtension:extension];
}

- (void)updatePlayerTimePositionWithDelta:(double)seconds {
    double newPosition = _player.timePosition + seconds;
    if (newPosition < 0.0) {
        newPosition = 0.0;
    } else if (newPosition > _player.currentItem.duration) {
        newPosition = _player.currentItem.duration;
    }
    _player.timePosition = newPosition;
}

- (SLHEncoderItem *)duplicateEncoderItem:(SLHEncoderItem *)sourceItem {
    SLHEncoderItem *encoderItem = _currentEncoderItem.copy;
    encoderItem.outputFileName = [self outputNameForDocument:encoderItem];
    return encoderItem;
}

- (void)resetWindow {
    
    self.currentEncoderItem = nil;
    _player.currentItem = nil;
    [_formatsArrayController.selection setValue:nil forKey:@"encoderItem"];
    NSWindow *window = self.window;
    window.representedURL = nil;
    window.title = @"";
    [_encoderSettings reloadTab];
    [_videoStreamPopUp removeAllItems];
    [_audioStreamPopUp removeAllItems];
    [_subtitlesStreamPopUp removeAllItems];
}

- (void)showSideBarIfNeeded {
    
    NSView *v = _encoderSettingsView;
    
    if ([_inspectorSplitView isSubviewCollapsed:v]) {
        [_inspectorSplitView setPosition:NSWidth(_inspectorSplitView.frame) - _sideBarWidth ofDividerAtIndex:0];
    }
}

- (BOOL)isSideBarHidden {
    return [_inspectorSplitView isSubviewCollapsed:_encoderSettingsView];
}

- (BOOL)loadFileURL:(NSURL *)url {
    MPVPlayerItem *playerItem = [MPVPlayerItem playerItemWithURL:url];
    if (playerItem.error) {
        NSError *e = playerItem.error;
        NSLog(@"Cannot load %@\n %@", url, e);
        NSAlert *alert = [NSAlert new];
        alert.messageText = [NSString stringWithFormat:@"Cannot open '%@'.",
                             url.lastPathComponent];
        alert.informativeText = e.localizedDescription;
        [alert runModal];
        return NO;
    }
    if (![self hasMediaStreams:playerItem]) {
        NSLog(@"Cannot load %@\n File doesn't contain playable streams.", url);
        NSAlert *alert = [NSAlert new];
        alert.messageText = [NSString stringWithFormat:@"Cannot open '%@'.",
                             url.lastPathComponent];
        alert.informativeText = @"File doesn't contain any playable streams.";
        [alert runModal];
        return NO;
    }
    [self createEncoderItemWith:playerItem];
    return YES;
}


- (void)createEncoderItemWith:(MPVPlayerItem *)playerItem {
    NSURL *url = playerItem.url;
    NSString *outputName = url.lastPathComponent;
    NSString *outputPath = [self outputPathForSourcePath:url.path];
    outputPath = [outputPath stringByAppendingPathComponent:outputName];
    SLHEncoderItem *encoderItem;
    encoderItem = [[SLHEncoderItem alloc] initWithPlayerItem:playerItem
                                                  outputPath:outputPath];
    [encoderItem matchSource];
    [self populatePopUpMenus:playerItem];
    [self updatePopUpMenus:encoderItem];
    [self updateWindowTitle:playerItem.url];
    encoderItem.tag =  _formatsPopUp.indexOfSelectedItem;
    
    if (NSApp.currentEvent.modifierFlags & NSEventModifierFlagOption) {
        NSArray *objects = _itemsArrayController.arrangedObjects;
        if (objects.count) {
            [_itemsArrayController removeObjects:objects];
        }
    }
    
    [_itemsArrayController addObject:encoderItem];
}

- (BOOL)hasMediaStreams:(MPVPlayerItem *)playerItem {
    return (playerItem.hasVideoStreams || playerItem.hasAudioStreams);
}

- (void)updateInputFileInfo:(MPVPlayerItem *)playerItem {
    
    MPVPlayerItemTrack *track = playerItem.bestVideoTrack;
    NSMutableString *result = nil;
    
    if (track) {
        result = [NSMutableString new];
        
        NSSize size = track.videoSize;
        [result appendFormat:@"%.0fx%.0f", size.width, size.height];
        [result appendFormat:@", %@", track.codecName];
        
        double fps = track.averageFrameRate;
        if (fps > 0) {
            [result appendFormat:@", %g fps", track.averageFrameRate];
        }
        
        [result appendFormat:@", %@", track.pixFormatName];

    }
    
    track = playerItem.bestAudioTrack;
    if (track) {
        if (result) {
            [result appendString:@" :: "];
        } else {
            result = [NSMutableString new];
        }
        
        [result appendString:track.language];
        [result appendFormat:@", %@", track.codecName];
        [result appendFormat:@", %@", track.channelLayout];
        [result appendFormat:@", %@", track.sampleFormatName];
        [result appendFormat:@", %luHz", track.sampleRate];
    }
    
    if (!result) {
        result = [@"Unknown :: " mutableCopy];
    } else {
        [result appendString:@" :: "];
    }

    
    NSString *tmp;
    tmp =  SLHBitrateFormatterStringForDoubleValue(playerItem.bitRate);
    [result appendFormat:@"%@", tmp];
    
    tmp = [NSByteCountFormatter stringFromByteCount:playerItem.fileSize
                                         countStyle:NSByteCountFormatterCountStyleBinary];
    [result appendFormat:@", %@", tmp];
    
    _inputFileInfoTextField.stringValue = result;
}

- (NSString *)outputPathForSourcePath:(NSString *)sourcePath {
    NSString *outputPath = nil;
    SLHPreferences *prefs = _preferences;
    if (prefs.outputPathSameAsInput) {
        outputPath = [sourcePath stringByDeletingLastPathComponent];
    } else {
        outputPath = prefs.currentOutputPath;
    }
    return outputPath;
}

- (void)matchVideoStreamsToEncoderItem:(SLHEncoderItem *)encoderItem {
    
    MPVPlayer *player = _player;
    
    NSInteger streamIdx = encoderItem.videoStreamIndex;
    if (streamIdx == -1) {
        [player setBool:NO
            forProperty:MPVPlayerPropertyVideoID];
    } else {
        [player setInteger:_videoStreamPopUp.indexOfSelectedItem + 1
               forProperty:MPVPlayerPropertyVideoID];
    }
    
    streamIdx = encoderItem.audioStreamIndex;
    if (streamIdx == -1) {
        [player setBool:NO
            forProperty:MPVPlayerPropertyAudioID];
    } else {
        [player setInteger:_audioStreamPopUp.indexOfSelectedItem + 1
               forProperty:MPVPlayerPropertyAudioID];
    }
    
    streamIdx = encoderItem.subtitlesStreamIndex;
    if (streamIdx == -1) {
        [player setBool:NO
            forProperty:MPVPlayerPropertySubtitleID];
    } else {
        [player setInteger:_subtitlesStreamPopUp.indexOfSelectedItem + 1
               forProperty:MPVPlayerPropertySubtitleID];
    }
}

- (void)previewFile:(NSURL *)mediaURL {
    SLTRemotePlayer *rp = SLTRemotePlayer.sharedInstance;
    rp.url = mediaURL;
    if (rp.error) {
        NSAlert *alert = [NSAlert new];
        alert.messageText = [NSString stringWithFormat:@"'%@' cannot open '%@'",
                                                       rp.mpvPath, mediaURL];
        alert.informativeText = rp.error.localizedDescription;
        [alert runModal];
        return;
    }
    [rp setVideoFilter:@""];
    [rp orderFront];
    [rp play];
}

- (void)createDefaultPresetMenuItems {
    NSMenuItem *separator = [NSMenuItem separatorItem];
    NSMenuItem *managePresets = [[NSMenuItem alloc] initWithTitle:@"Manage Presets" action:@selector(showPresetsWindow:) keyEquivalent:@""];
    managePresets.target = _presetManager;
    NSMenuItem *savePreset = [[NSMenuItem alloc] initWithTitle:@"Save Preset" action:@selector(savePreset:) keyEquivalent:@""];
    savePreset.target = self;
    _defaultPresetMenuItems = @[separator, savePreset, managePresets];
}

#pragma mark - KVO

- (void)observePreferences:(SLHPreferences *)appPrefs {
    __unsafe_unretained typeof(self) uSelf = self;
    __unsafe_unretained typeof(_player) player = _player;
    __unsafe_unretained typeof(appPrefs) prefs = appPrefs;
    _prefsObservers =
    @[
      // MARK: Screenshot directory save path
      [appPrefs observeKeyPath: SLHPreferencesScreenshotPathKey handler:
       ^(id obj, NSString * _Nonnull keyPath, NSString *_Nonnull change) {
           [player setString: change
                 forProperty: MPVPlayerPropertyScreenshotDirectory];
       }],
      
      // MARK: Screenshot file format
      [appPrefs observeKeyPath: SLHPreferencesScreenshotFormatKey handler:
       ^(id obj, NSString * _Nonnull keyPath, NSString *_Nonnull change) {
           [player setString: change
                 forProperty: MPVPlayerPropertyScreenshotFormat];
       }],
      
      // MARK: Screenshot template name
      [appPrefs observeKeyPath: SLHPreferencesScreenshotTemplateKey handler:
       ^(id obj, NSString * _Nonnull keyPath, NSString *_Nonnull change){
           [player setString: change
                 forProperty: MPVPlayerPropertyScreenshotTemplate];
       }],
      
      // MARK: Screenshot JPEG quality
      [appPrefs observeKeyPath: SLHPreferencesScreenshotJPGQualityKey handler:
       ^(id obj, NSString * _Nonnull keyPath, NSNumber * _Nonnull change) {
           [player setInteger: change.integerValue
                  forProperty: MPVPlayerPropertyScreenshotJPGQuality];
       }],
      
      // MARK: Screenshot PNG compression
      [appPrefs observeKeyPath: SLHPreferencesScreenshotPNGCompressionKey
        handler:^(id obj, NSString * _Nonnull kp, NSNumber * _Nonnull change) {
           [player setInteger: change.integerValue
                  forProperty: MPVPlayerPropertyScreenshotPNGCompression];
       }],
      
      // MARK: OSD font name
      [appPrefs observeKeyPath: SLHPreferencesOSDFontNameKey handler:
       ^(id obj, NSString * _Nonnull keyPath, NSString * _Nonnull change) {
           [player setString: change
                 forProperty: MPVPlayerPropertyOSDFontName];
       }],
      
      // MARK: OSD font size
      [appPrefs observeKeyPath: SLHPreferencesOSDFontSizeKey handler:
       ^(id obj, NSString * _Nonnull keyPath, NSNumber * _Nonnull change) {
           [player setInteger: change.integerValue
                  forProperty: MPVPlayerPropertyOSDFontSize];
       }],
      
      // MARK: OSD font scale
      [appPrefs observeKeyPath: SLHPreferencesOSDFontScaleByWindowKey handler:
       ^(id obj, NSString * _Nonnull keyPath, NSNumber * _Nonnull change) {
           [player setBool: change.boolValue
               forProperty: MPVPlayerPropertyOSDFontScaleByWindow];
       }],
      
      // MARK: Subtitles font name
      [appPrefs observeKeyPath: SLHPreferencesSubtitlesFontNameKey handler:
       ^(id obj, NSString * _Nonnull keyPath, NSString * _Nonnull change) {
           [player setString: change
                 forProperty: MPVPlayerPropertySubsFontName];
       }],
      
      // MARK: Subtitles font size
      [appPrefs observeKeyPath: SLHPreferencesSubtitlesFontSizeKey handler:
       ^(id obj, NSString * _Nonnull keyPath, NSNumber * _Nonnull change) {
           [player setInteger: change.integerValue
                  forProperty: MPVPlayerPropertySubsFontSize];
       }],
      
      // MARK: Subtitles font scale
      [appPrefs observeKeyPath: SLHPreferencesSubtitlesFontScaleByWindowKey
        handler:^(id obj, NSString *_Nonnull kp, NSNumber *_Nonnull change) {
           [player setBool: change.boolValue
               forProperty: MPVPlayerPropertySubsFontScaleByWindow];
       }],
      
      // MARK: Last edited advanced option
      [appPrefs observeKeyPath: SLHPreferencesAdvancedOptionsLastEditedKey
        handler:^(id obj, NSString * _Nonnull kp, id _Nonnull option) {
           NSError *error = nil;
           id value = [option valueForKey:SLHPreferencesAdvancedOptionValueKey];
           id key = [option valueForKey:SLHPreferencesAdvancedOptionNameKey];
           if (![player setString:value forProperty:key error:&error]) {
               [NSApp presentError:error];
           }
       }],
      
      // MARK: Enable advanced options
      [appPrefs observeKeyPath: SLHPreferencesAdvancedOptionsEnabledKey handler:
       ^(id obj, NSString * _Nonnull keyPath, NSNumber * _Nonnull change) {
           if (!change.boolValue) return;
           
           NSDictionary *advancedOptions = prefs.advancedOptions;
           if (!advancedOptions.count) return;
           
           [advancedOptions enumerateKeysAndObjectsUsingBlock:
            ^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                NSError *error = nil;
                if (![player setString:obj forProperty:key error:&error]) {
                    [NSApp presentError:error];
                }
            }];
       }],
      
      // MARK: Window title style
      [appPrefs observeKeyPath: SLHPreferencesWindowTitleStyleKey handler:
       ^(id obj, NSString * _Nonnull keyPath, NSNumber * _Nonnull change) {
           // FIXME: Big Sur's toolbars
           NSWindowTitleVisibility value = change.integerValue;
           NSWindow *window = uSelf.window;
           window.titleVisibility = value;
           SLHEncoderItem *current = uSelf->_currentEncoderItem;
           if (current) {
               // reset the url, otherwise the window won't
               // update its file icon properly
               window.representedURL = nil;
               NSURL * url = current.playerItem.url;
               window.representedURL = url;
               window.title = url.lastPathComponent;
           }
       }],
      
      // MARK: MPV path
      [appPrefs observeKeyPath: SLHPreferencesMPVPathKey handler:
       ^(id obj, NSString * _Nonnull keyPath, NSString * _Nonnull change) {
           [SLTRemotePlayer.sharedInstance setMpvPathAndReload:change];
       }],
      
      // MARK: ffmpeg path
      [appPrefs observeKeyPath: SLHPreferencesFFMpegPathKey handler:
       ^(SLHPreferences *_Nonnull prefs, id kp, NSString *_Nonnull change) {
           [SLKFFmpegInfoController.sharedInstance
            updateInfoWithPath:(prefs.hasFFmpeg) ? change : nil];
      }],
      
      // MARK: Output name template format
      [appPrefs observeKeyPath: SLHPreferencesOutputNameTemplateKey handler:
       ^(id obj, NSString * _Nonnull keyPath, NSString * _Nonnull change) {
           uSelf->_templateNameFormatter.templateFormat = change;
       }],
      
      // MARK: Enable output name template formatting
      [appPrefs observeKeyPath: SLHPreferencesEnableOutputNameTemplateKey
       handler:^(id obj, NSString * _Nonnull kp, NSNumber * _Nonnull change) {
           BOOL result = change.boolValue;
           uSelf->_outputNameController.nameEditable = result ? NO : YES;
       }],
    ];
}

- (void)unobservePreferences {
    _prefsObservers = nil;
}

#pragma mark - PopUp Menus

- (void)populatePopUpMenus:(MPVPlayerItem *)playerItem {
    NSMenuItem *item;
    [_videoStreamPopUp removeAllItems];
    [_audioStreamPopUp removeAllItems];
    [_subtitlesStreamPopUp removeAllItems];
    
    for (MPVPlayerItemTrack *t in playerItem.tracks) {
        NSUInteger trackIndex = t.trackIndex;
        switch (t.mediaType) {
            case MPVMediaTypeVideo:
            {
                NSSize videoSize = t.videoSize;
                NSSize codedVideoSize = t.codedVideoSize;
                NSString *videoSizeString = [NSString stringWithFormat:@"%.0fx%.0f", videoSize.width, videoSize.height];
                if (videoSize.width != codedVideoSize.width ||
                    videoSize.height != codedVideoSize.height) {
                    videoSizeString = [NSString stringWithFormat:@"%@ (coded %.0fx%.0f)", videoSizeString, codedVideoSize.width, codedVideoSize.height];
                }
                
                item = [[NSMenuItem alloc] initWithTitle:
                        [NSString stringWithFormat:@"%lu: %@, %@ [SAR %.0f:%.0f, DAR %.0f:%.f], %g fps, %g tbr",
                         trackIndex,
                         t.codecName,
                         videoSizeString,
                         t.sampleAspectRatio.width,
                         t.sampleAspectRatio.height,
                         t.displayAspectRatio.width,
                         t.displayAspectRatio.height,
                         t.averageFrameRate,
                         t.realBaseFrameRate]
                                                  action:@selector(videoStreamPopUpAction:)
                                           keyEquivalent:@""];
                item.tag = trackIndex;
                item.target = self;
                [_videoStreamPopUp.menu addItem:item];
            }
                break;
            case MPVMediaTypeAudio:
            {
                item = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%lu: %@, %@, %@, %llukbs", trackIndex, t.codecName, t.language, t.channelLayout, t.bitRate / 1000] action:@selector(audioStreamPopUpAction:) keyEquivalent:@""];
                item.tag = trackIndex;
                item.target = self;
                [_audioStreamPopUp.menu addItem:item];
            }
                break;
            case MPVMediaTypeText:
            {
                item = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%lu: %@, %@", trackIndex, t.language, t.codecName] action:@selector(subtitlesStreamPopUpAction:) keyEquivalent:@""];
                item.tag = trackIndex;
                item.target = self;
                [_subtitlesStreamPopUp.menu addItem:item];
            }
                break;
                
            default:
                break;
        }
    }
    item = [[NSMenuItem alloc] initWithTitle:@"none" action:@selector(videoStreamPopUpAction:) keyEquivalent:@""];
    item.tag = -1;
    item.target = self;
    [_videoStreamPopUp.menu addItem:item.copy];
    item.action = @selector(audioStreamPopUpAction:);
    [_audioStreamPopUp.menu addItem:item.copy];
    item.action = @selector(subtitlesStreamPopUpAction:);
    [_subtitlesStreamPopUp.menu addItem:item.copy];
}

- (void)updatePopUpMenus:(SLHEncoderItem *)item {
    [_videoStreamPopUp selectItemWithTag:item.videoStreamIndex];
    [_audioStreamPopUp selectItemWithTag:item.audioStreamIndex];
    [_subtitlesStreamPopUp selectItemWithTag:item.subtitlesStreamIndex];
}

#pragma mark - IBActions

- (IBAction)trimViewGoToCurrentPlaybackPosition:(id)sender {
    [_trimViewController goToCurrentPlaybackPosition];
}

- (IBAction)trimViewGoToStart:(id)sender {
    _player.timePosition = 0.0;
    [_trimViewController goToStart];
}

- (IBAction)trimViewGoToEnd:(id)sender {
    _player.timePosition = _player.currentItem.duration;
    [_trimViewController goToEnd];
}

- (IBAction)showTrimViewSettings:(NSButton *)sender {
    if (_trimViewSettingsPopover.shown) {
        [_trimViewSettingsPopover close];
    } else {
        [_trimViewSettingsPopover showRelativeToRect:sender.frame
                                              ofView:sender.superview
                                       preferredEdge:NSMinYEdge];
    }
}

- (IBAction)jumpToNearestKeyframe:(id)sender {
    double inc = 1.0 / (_currentEncoderItem.playerItem.bestVideoTrack.averageFrameRate + 0.01);
    if (inc > 0) {
        [_player seekTo:_player.timePosition - inc];
    }
}

- (IBAction)frameStep:(id)sender {
    [_player performCommand:MPVPlayerCommandFrameStep];
}

- (IBAction)frameBackStep:(id)sender {
    [_player performCommand:MPVPlayerCommandFrameBackStep];
}

- (IBAction)jumpForwardFine:(id)sender {
    [self updatePlayerTimePositionWithDelta:30.0];
}

- (IBAction)jumpBackFine:(id)sender {
    [self updatePlayerTimePositionWithDelta:-30.0];
}

- (IBAction)jumpForward:(id)sender {
    [self updatePlayerTimePositionWithDelta:60.0];
}

- (IBAction)jumpBack:(id)sender {
    [self updatePlayerTimePositionWithDelta:-60.0];
}

- (IBAction)stepForwardFine:(id)sender {
    [self updatePlayerTimePositionWithDelta:1.0];
}

- (IBAction)stepBackFine:(id)sender {
    [self updatePlayerTimePositionWithDelta:-1.0];
}

- (IBAction)stepForward:(id)sender {
    [self updatePlayerTimePositionWithDelta:5.0];
}

- (IBAction)stepBack:(id)sender {
    [self updatePlayerTimePositionWithDelta:-5.0];
}

- (IBAction)showEncoderHistroy:(id)sender {
    [_encoderHistory showWindow:nil];
}

- (IBAction)toggleOSDFractions:(id)sender {
    BOOL flag = [_player boolForProperty:MPVPlayerPropertyOSDFractions];
    if (flag) {
        flag = NO;
    } else {
        flag = YES;
    }
    [_player setBool:flag forProperty:MPVPlayerPropertyOSDFractions];
}

- (IBAction)toggleOSD:(id)sender {
    NSInteger level = [_player integerForProperty:MPVPlayerPropertyOSDLevel];
    if (level == 3) {
        level = 0;
         [_player printOSDMessage:@"OSD: off"];
    } else {
        level++;
        if (level == 1) {
            [_player printOSDMessage:@"OSD: 1"];
        }
    }
     [_player setInteger:level forProperty:MPVPlayerPropertyOSDLevel];
}

- (IBAction)increasePlaybackSpeed:(id)sender {
    double speed = _player.speed;
    if (NSApp.currentEvent.modifierFlags & NSEventModifierFlagOption) {
        speed += 0.5;
    } else {
        speed += 0.1;
    }
    _player.speed = speed;
    [_player printOSDMessage:[NSString stringWithFormat:@"Speed: x%.1f", speed]];
}

- (IBAction)decreasePlaybackSpeed:(id)sender {
    double speed = _player.speed;
    if (NSApp.currentEvent.modifierFlags & NSEventModifierFlagOption) {
        speed -= 0.5;
    } else {
        speed -= 0.1;
    }
    
    if (speed < 0.1) {
        speed = 0.1;
    }
     _player.speed = speed;
    [_player printOSDMessage:[NSString stringWithFormat:@"Speed: x%.1f", speed]];
}

- (IBAction)resetPlaybackSpeed:(id)sender {
    _player.speed = 1.0;
    [_player printOSDMessage:@"Speed: x1.0"];
}

- (IBAction)matchToSelectedRange:(id)sender {
    SLHPlayerViewController * playerController = _playerView.viewController;
    double outMark = playerController.outMark;
    
    if (outMark == 0) {
        NSBeep();
        return;
    }
    
    double inMark = playerController.inMark;
    SLHEncoderItem *currentItem = _currentEncoderItem;
    TimeInterval interval = currentItem.interval;
    if (inMark > interval.end) {
        currentItem.intervalEnd = outMark;
        currentItem.intervalStart = inMark;
    } else {
        currentItem.intervalStart = inMark;
        currentItem.intervalEnd = outMark;
    }
    
    [_player seekExactTo:inMark];
}

- (IBAction)duplicateAndMatchToSelectedRange:(id)sender {

    SLHPlayerViewController * playerController = _playerView.viewController;
    
    double end = playerController.outMark;
    
    if (end == 0) {
        NSBeep();
        return;
    }
    
    double start = playerController.inMark;
    
    SLHEncoderItem *currentItem = _currentEncoderItem;
    SLHEncoderItem *duplicate = [self duplicateEncoderItem:currentItem];
    
    duplicate.intervalEnd = end;
    duplicate.intervalStart = start;
    
    [_itemsArrayController insertObject:duplicate
                  atArrangedObjectIndex:[_itemsArrayController.arrangedObjects
                                         indexOfObject:currentItem] + 1];
    
    [_player seekExactTo:start];
}

- (IBAction)resetSelection:(id)sender {
    SLHEncoderItem *currentItem = _currentEncoderItem;
    currentItem.intervalStart = 0;
    currentItem.intervalEnd = currentItem.playerItem.duration;
}

- (IBAction)jumpToStartPosition:(id)sender {
    _player.timePosition = _currentEncoderItem.interval.start;
    [_trimViewController goToSelectionStart];
}

- (IBAction)jumpToEndPosition:(id)sender {
    _player.timePosition = _currentEncoderItem.interval.end;
    [_trimViewController goToSelectionEnd];
}

- (IBAction)toggleSideBar:(id)sender {
    CGFloat width = [_inspectorSplitView isSubviewCollapsed:_encoderSettingsView] ? _sideBarWidth : 0;
    [_inspectorSplitView setPosition:NSWidth(_inspectorSplitView.frame) - width ofDividerAtIndex:0];
}

- (IBAction)showSideBar:(id)sender {
    [_inspectorSplitView setPosition:NSWidth(_inspectorSplitView.frame) - _sideBarWidth ofDividerAtIndex:0];
}

- (IBAction)hideSideBar:(id)sender {
    [_inspectorSplitView setPosition:NSWidth(_inspectorSplitView.frame) ofDividerAtIndex:0];
}

- (IBAction)showMetadataEditor:(id)sender {
    [self showSideBarIfNeeded];
    _encoderSettings.selectedTab = SLHEncoderSettingsMetadataInspectorTab;
}

- (IBAction)showFileInfo:(id)sender {
    [self showSideBarIfNeeded];
    _encoderSettings.selectedTab = SLHEncoderSettingsFileInfoTab;
}

- (IBAction)showFiltersSettings:(id)sender {
    [self showSideBarIfNeeded];
    _encoderSettings.selectedTab = SLHEncoderSettingsFiltersTab;
}

- (IBAction)showAudioSettings:(id)sender {
    [self showSideBarIfNeeded];
    _encoderSettings.selectedTab = SLHEncoderSettingsAudioTab;
}

- (IBAction)showVideoSettings:(id)sender {
    [self showSideBarIfNeeded];
    _encoderSettings.selectedTab = SLHEncoderSettingsVideoTab;
}

- (IBAction)previewSourceFile:(id)sender {
    SLHEncoderItem *encoderItem = _currentEncoderItem;
    [self previewFile:encoderItem.playerItem.url];
}

- (IBAction)previewSegment:(id)sender {
    SLHPlayerViewController *playerController = _playerView.viewController;
    TimeInterval interval = _currentEncoderItem.interval;
    [playerController loopPlaybackWithStart:interval.start end:interval.end];
}

- (IBAction)previewOutputFile:(id)sender {
    [self previewFile:[NSURL fileURLWithPath:_lastEncodedMediaFilePath]];
}

- (IBAction)addSelectionToQueue:(id)sender {
    NSEventModifierFlags flags = NSApp.currentEvent.modifierFlags;
    [self.window endEditingFor:nil];
    SLHEncoderItem *currentEncoderItem = _currentEncoderItem;
    if (_preferences.enableOutputNameTemplate) {
        NSString *outputName = [self outputNameForDocument:currentEncoderItem];
        currentEncoderItem.outputFileName = outputName;
    }
    
    currentEncoderItem.encoderArguments = [_formatsArrayController.selection valueForKey:@"arguments"];
    [_queue addEncoderItems:@[currentEncoderItem]];
    
    if (flags & NSEventModifierFlagOption) {
        [self removeEncoderItem:sender];
    }
}

- (IBAction)addAllToQueue:(id)sender {
    NSEventModifierFlags flags = NSApp.currentEvent.modifierFlags;
    [self.window endEditingFor:nil];
    
    BOOL shouldUseTemplate = _preferences.enableOutputNameTemplate;
    
    NSArray *items = _itemsArrayController.arrangedObjects;
    NSArray *formats = _formatsArrayController.arrangedObjects;
    
    for (SLHEncoderItem *i in items) {
        if (shouldUseTemplate) {
            i.outputFileName = [self outputNameForDocument:i];
        }
        SLHEncoderBaseFormat *fmt = formats[i.tag];
        fmt.encoderItem = i;
        i.encoderArguments = fmt.arguments;
    }
    [_queue addEncoderItems:items];
    
    if (flags & NSEventModifierFlagOption) {
        [_itemsArrayController removeObjects:items];
        [self resetWindow];
    }
}

- (IBAction)showQueue:(id)sender {
    [_queue.window makeKeyAndOrderFront:nil];
}

- (IBAction)showFFmpegInfo:(id)sender {
    [SLKFFmpegInfoController.sharedInstance.window makeKeyAndOrderFront:nil];
}

- (IBAction)showPresetsWindow:(id)sender {
    [_presetManager.window makeKeyAndOrderFront:sender];
}

- (IBAction)loadPreset:(NSMenuItem *)sender {
    SLHEncoderBaseFormat * baseFormat = _formatsArrayController.selectedObjects.firstObject;
    baseFormat.dictionaryRepresentation = sender.representedObject;
    [self updatePopUpMenus:_currentEncoderItem];
}

- (IBAction)savePreset:(id)sender {
    SLHEncoderBaseFormat * baseFormat = _formatsArrayController.selectedObjects.firstObject;
    [_presetManager setPreset:baseFormat.dictionaryRepresentation forName:baseFormat.formatName];
}

- (IBAction)startEncoding:(id)sender {
    NSWindow *window = self.window;
    if (![window makeFirstResponder:window]) {
        NSBeep();
        return;
    }
    
    const NSEventModifierFlags
    shouldEditArgs = NSApp.currentEvent.modifierFlags & NSEventModifierFlagOption;
    SLHEncoderItem *currentEncoderItem = _currentEncoderItem;
    if (_preferences.enableOutputNameTemplate) {
        NSString *outputName = [self outputNameForDocument:currentEncoderItem];
        currentEncoderItem.outputFileName = outputName;
    }
    
    if (!_preferences.shouldOverwriteFiles &&
        [[NSFileManager defaultManager]
         fileExistsAtPath:currentEncoderItem.outputPath isDirectory:nil])
    {
        NSString *question = @"Overwrite file?";
        NSString *info = [NSString stringWithFormat:@"File '%@' already exists.",
                          currentEncoderItem.outputPath];
        NSString *firstButton = @"Cancel";
        NSString *secondButton = @"OK";
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = question;
        alert.informativeText = info;
        [alert addButtonWithTitle:firstButton];
        [alert addButtonWithTitle:secondButton];
        
        if ([alert runModal] == NSAlertFirstButtonReturn) {
            return;
        }
    }
    
    currentEncoderItem.encoderArguments = [_formatsArrayController.selection
                                           valueForKey:@"arguments"];
    
    if (shouldEditArgs) {
        SLHModalWindowController *win = [[SLHModalWindowController alloc] init];
        SLHArgumentsViewController *argsView =
        [[SLHArgumentsViewController alloc] init];
        win.title = @"Encoding Arguments";
        win.contentView = argsView.view;
        argsView.encoderItem = currentEncoderItem;
        [win.window setFrame:NSMakeRect(0, 0, 360, 640) display:NO];
        [win runModal];
    }
     __unsafe_unretained typeof(self) obj = self;
    
    [_encoder encodeItem:currentEncoderItem
              usingBlock:^(SLHEncoderState state) {
        switch (state)  {
                
            case SLHEncoderStateSuccess: {
                obj.lastEncodedMediaFilePath = currentEncoderItem.outputPath;
                if (obj->_preferences.updateFileName) {
                    [obj updateOutputFileName:sender];
                }
                
                NSString *log = obj->_encoder.encodingLog;
                [obj->_encoderHistory addItemWithPath:obj->_lastEncodedMediaFilePath
                                                  log: log ? log : @""];
                
                break;
            }
                
            case SLHEncoderStateFailed: {
                NSString *log = obj->_encoder.encodingLog;
                if (log) {
                    SLHLogController * logWindow = [[SLHLogController alloc] init];
                    logWindow.log = log;
                    [logWindow runModal];
                }
                break;
            }
                
            case SLHEncoderStateCanceled: {
                break;
            }
                
            default:
                break;
        }
        [obj->_encoder.window performClose:nil];
    }];
}

- (IBAction)updateOutputFileName:(id)sender {
    
    SLHEncoderItem *encoderItem = _currentEncoderItem;
    encoderItem.outputFileName = [self outputNameForDocument:encoderItem];
}

- (IBAction)addEncoderItem:(id)sender {
    SLHEncoderItem *currentEncoderItem = _currentEncoderItem;
    if (currentEncoderItem) {
        SLHEncoderItem *encoderItem = [self duplicateEncoderItem:currentEncoderItem];
        [_itemsArrayController insertObject:encoderItem
                      atArrangedObjectIndex:[_itemsArrayController.arrangedObjects indexOfObject:currentEncoderItem] + 1];
        
        // Force Key-Value observer to update
        encoderItem.intervalStart = currentEncoderItem.interval.start;
        
    } else {
        NSOpenPanel *panel = [NSOpenPanel openPanel];
        panel.allowsMultipleSelection = NO;
        
        if ([panel runModal] == NSModalResponseOK) {
            
            NSURL *url = panel.URL;
            if ([self loadFileURL:url]) {
                [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:url];
            } else {
                NSBeep();
            }
        }
    }
}

- (IBAction)removeEncoderItem:(id)sender {
    [_itemsArrayController remove:sender];
    if (!_itemsArrayController.canRemove) {
        [self resetWindow];
    }
}

- (IBAction)videoStreamPopUpAction:(NSMenuItem *)sender {
    NSInteger tag = sender.tag;
    _currentEncoderItem.videoStreamIndex = tag;
    
    if (tag == -1) {
        [_player setBool:NO
                          forProperty:MPVPlayerPropertyVideoID];
    } else {
        [_player setInteger:[sender.menu indexOfItem:sender] + 1
                           forProperty:MPVPlayerPropertyVideoID];
    }
}

- (IBAction)audioStreamPopUpAction:(NSMenuItem *)sender {
    NSInteger tag = sender.tag;
    _currentEncoderItem.audioStreamIndex = tag;
    
    if (tag == -1) {
        [_player setBool:NO
                          forProperty:MPVPlayerPropertyAudioID];
    } else {
        [_player setInteger:[sender.menu indexOfItem:sender] + 1
                           forProperty:MPVPlayerPropertyAudioID];
    }
}

- (IBAction)subtitlesStreamPopUpAction:(NSMenuItem *)sender {
    NSInteger tag = sender.tag;
    _currentEncoderItem.subtitlesStreamIndex = tag;
    
    if (tag == -1) {
        [_player setBool:NO
                          forProperty:MPVPlayerPropertySubtitleID];
    } else {
        [_player setInteger:[sender.menu indexOfItem:sender] + 1
                           forProperty:MPVPlayerPropertySubtitleID];
    }
}

- (IBAction)formatsPopUpAction:(id)sender {
    SLHEncoderBaseFormat * encoderFormat = _formatsArrayController.selectedObjects.firstObject;
    SLHEncoderItem *encoderItem = _itemsArrayController.selectedObjects.firstObject;
    encoderFormat.encoderItem = encoderItem;
    encoderItem.tag = _formatsArrayController.selectionIndex;
    _encoderSettings.delegate = encoderFormat;
    encoderFormat.view.needsDisplay = YES;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SLHEncoderFormatDidChangeNotification object:encoderFormat];
}

- (IBAction)selectOutputPath:(NSButton *)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = NO;
    panel.canChooseFiles = NO;
    panel.canChooseDirectories = YES;
    panel.canCreateDirectories = YES;
    NSModalResponse returnCode = [panel runModal];
    
    if (returnCode == NSModalResponseOK) {
        NSString *path = panel.URL.path;
        SLHEncoderItem *encoderItem = _currentEncoderItem;
        NSString *outname = encoderItem.outputPath.lastPathComponent;
        encoderItem.outputPath = [path stringByAppendingPathComponent:outname];
    }
}

#pragma mark - SLHPlayerViewController Notificaitons

- (void)playerViewControllerDidChangeInMark:(NSNotification *)n {
    SLHPlayerViewController *playerController = n.object;
    _currentEncoderItem.intervalStart = playerController.inMark;
}

- (void)playerViewControllerDidChangeOutMark:(NSNotification *)n {
    SLHPlayerViewController *playerController = n.object;
    _currentEncoderItem.intervalEnd = playerController.outMark;
}

- (void)playerViewControllerDidCommitInOutMarks:(NSNotification *)n {
    [self duplicateAndMatchToSelectedRange:nil];
}

#pragma mark - MPVPlayer Notifications

- (void)playerDidLoadFile:(NSNotification *)n {
    SLHEncoderItem *currentEncoderItem = _currentEncoderItem;
    [_player seekExactTo:currentEncoderItem.interval.start];
    [self matchVideoStreamsToEncoderItem:currentEncoderItem];
    [_player pause];
}

#pragma mark - NSApplication Notifications

- (void)applicationWillTerminate:(NSNotification *)n {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [SLTRemotePlayer.sharedInstance quit];
    _preferences.lastUsedFormatName = _formatsPopUp.selectedItem.title;
    if (_presetManager.hasChanges) {
        [_presetManager savePresets];
    }
    [self unobservePreferences];
    [_player quit];
    _player = nil;
    self.currentEncoderItem = nil;
    [_itemsArrayController removeObjects:_itemsArrayController.arrangedObjects];
}

#pragma mark - NSDraggingDestination

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    NSPasteboard *pboard;
    pboard = [sender draggingPasteboard];
    
    if ([pboard.types containsObject:kSLTTypeFileURL]) {
        return NSDragOperationGeneric;
    }
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    NSPasteboard *pboard;
    BOOL result = NO;
    pboard = [sender draggingPasteboard];

    if ([pboard.types containsObject:kSLTTypeFileURL]) {
        NSString *path = [pboard propertyListForType:kSLTTypeFileURL];
        NSURL *url = [NSURL URLWithString:path];
        path = url.path;
        MPVPlayerItem *playerItem = [MPVPlayerItem playerItemWithPath:path];
        if (playerItem.error) {
            NSAlert *alert = [NSAlert new];
            alert.messageText = [NSString stringWithFormat:@"Cannot load %@", path];
            alert.informativeText = playerItem.error.localizedDescription;
            [alert runModal];
            return NO;
        }
        
        if (![self hasMediaStreams:playerItem]) {
            NSAlert *alert = [NSAlert new];
            alert.messageText = [NSString stringWithFormat:@"Cannot load %@", path];
            alert.informativeText = @"File doesn't not contain playable streams.";
            [alert runModal];
            return NO;
        }
        [self createEncoderItemWith:playerItem];
        [NSDocumentController.sharedDocumentController noteNewRecentDocumentURL:[NSURL fileURLWithPath:path]];
        result = YES;
    }
    return result;
}

- (void)updateWindowTitle:(NSURL *)url {
    NSWindow *window = self.window;
    window.title = url.lastPathComponent;
    window.representedURL = url;
}

#pragma mark - NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
     SLHEncoderItem *encoderItem = _itemsArrayController.selectedObjects.firstObject;
    
    /* Check if already selected */
    SLHEncoderItem *currentEncoderItem = _currentEncoderItem;
    if (encoderItem == currentEncoderItem) {
        return;
    }
    
    [_formatsArrayController setSelectionIndex:encoderItem.tag];
    SLHEncoderBaseFormat *fmt = _formatsArrayController.selectedObjects.firstObject;
    fmt.encoderItem = encoderItem;
    _encoderSettings.delegate = fmt;
    
    MPVPlayer *player = _player;
    MPVPlayerItem *playerItem = encoderItem.playerItem;
    if (playerItem != currentEncoderItem.playerItem) {
        [player pause];
        self.currentEncoderItem = encoderItem;
        
        [self populatePopUpMenus:playerItem];
        [self updateWindowTitle:playerItem.url];
        [self updatePopUpMenus:encoderItem];

        player.currentItem = playerItem;
        [self updateInputFileInfo:playerItem];
 
    } else {
        
        self.currentEncoderItem = encoderItem;
        [self updatePopUpMenus:encoderItem];
        [self matchVideoStreamsToEncoderItem:encoderItem];
    }
}

#pragma mark - NSMenuDelegate

- (void)menuNeedsUpdate:(NSMenu *)menu {
    NSMenuItem *titleItem = menu.itemArray.firstObject;
    [menu removeAllItems];
    [menu addItem:titleItem];
    
    SLHEncoderBaseFormat *baseFormat = _formatsArrayController.selectedObjects.firstObject;
    NSArray *presets = [_presetManager presetsForName:baseFormat.formatName];
    
    if (presets && presets.count) {
        for (NSDictionary *preset in presets) {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:preset[SLHEncoderPresetNameKey] action:@selector(loadPreset:) keyEquivalent:@""];
            menuItem.representedObject = preset;
            [menu addItem:menuItem];
        }

    }
    
    for (NSMenuItem *item in _defaultPresetMenuItems) {
        [menu addItem:item];
    }
    
}

#pragma mark - SLHPresetManagerDelegate

- (void)presetManager:(SLHPresetManager *)manager loadPreset:(NSDictionary *)preset forName:(NSString *)name {
    [_formatsPopUp selectItemWithTitle:name];
    [self formatsPopUpAction:_formatsPopUp];
    
    SLHEncoderBaseFormat *baseFormat = _formatsArrayController.selectedObjects.firstObject;
    baseFormat.dictionaryRepresentation = preset;
    [self updatePopUpMenus:_currentEncoderItem];
}

#pragma mark - NSWindowDelegate

- (void)windowWillStartLiveResize:(NSNotification *)notification {
    _sideBarWidth = NSWidth(_encoderSettingsView.frame);
    _bottomBarHeight = NSHeight(_bottomBarView.frame);
    _encoderItemsViewWidth =  NSWidth(_encoderItemsView.frame);
}

- (void)windowWillEnterFullScreen:(NSNotification *)notification {
    _sideBarWidth = NSWidth(_encoderSettingsView.frame);
    _bottomBarHeight = NSHeight(_bottomBarView.frame);
    _encoderItemsViewWidth =  NSWidth(_encoderItemsView.frame);
}

- (void)windowWillExitFullScreen:(NSNotification *)notification {
    _sideBarWidth = NSWidth(_encoderSettingsView.frame);
    _bottomBarHeight = NSHeight(_bottomBarView.frame);
    _encoderItemsViewWidth =  NSWidth(_encoderItemsView.frame);
}

#pragma mark - NSSplitViewDelegate

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {
    if (subview == _encoderSettings.view) {
        return YES;
    }
    if (subview == _encoderItemsView) {
        return YES;
    }
    return NO;
}
- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)view {
    return YES;
}

//#if 0

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex {
    if (splitView == _inspectorSplitView) {
        return NSWidth(splitView.frame) - 235;
    } else if (splitView == _trimSplitView) {
        return 400; // maximum width of encoder items table
    }
    return NSHeight(splitView.frame) - 100; // minimum bottomBar height
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex {
    if (splitView == _inspectorSplitView) {
        return NSWidth(splitView.frame) - 280;
    } else if (splitView == _trimSplitView) {
        return 210; // minimum width of encoder items table
    }
    return 280; // minimum videoView height
}

- (void)splitView:(NSSplitView*)splitView resizeSubviewsWithOldSize:(NSSize)oldSize {
   [splitView adjustSubviews];
    if (self.window.inLiveResize) {
        if (splitView == _inspectorSplitView) {
            if (![splitView isSubviewCollapsed:_encoderSettings.view]) {
                [splitView setPosition:(NSWidth(splitView.frame) - _sideBarWidth) ofDividerAtIndex:0];
            }
            return;
        }
        else if (splitView == _trimSplitView) {
            if (![splitView isSubviewCollapsed:_encoderItemsView]) {
               [splitView setPosition:_encoderItemsViewWidth
                     ofDividerAtIndex:0];
            }
            return;
        }
        [splitView setPosition:(NSHeight(splitView.frame) - _bottomBarHeight) ofDividerAtIndex:0];
    }
}

//#endif

#if 0
- (CGFloat)splitView:(NSSplitView *)splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex {
    
    NSRect frame = splitView.frame;
    
    if (splitView == _inspectorSplitView) {
        CGFloat minPosition = NSWidth(frame) - 200;
        CGFloat maxPostion = NSWidth(frame) - 260;
        if (proposedPosition > minPosition) {
            return minPosition;
        }
        
        if (proposedPosition < maxPostion) {
            return maxPostion;
        }
        
        return proposedPosition;
        
    } else {
        CGFloat minPosition = NSHeight(frame) - 100;
        CGFloat maxPostion = NSHeight(frame) - 220;
        
        if (proposedPosition > minPosition) {
            return minPosition;
        }
        
        if (proposedPosition < maxPostion) {
            return maxPostion;
        }
        return proposedPosition;
    }
    
    return proposedPosition;
}
#endif

@end
