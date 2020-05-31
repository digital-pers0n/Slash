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
#import "SLHExternalPlayer.h"
#import "SLHPlayerViewController.h"
#import "SLHMethodAddress.h"
#import "SLHEncoderHistory.h"
#import "SLHBitrateFormatter.h"
#import "SLHTrimViewController.h"
#import "SLHTrimViewSettings.h"
#import "SLHOutputNameController.h"
#import "SLHTemplateNameFormatter.h"

#import "MPVPlayer.h"
#import "MPVPlayerItem.h"
#import "MPVPlayerItemTrack.h"
#import "MPVPlayerProperties.h"
#import "MPVPlayerCommands.h"

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
    __weak SLHExternalPlayer *_externalPlayer;
    SLHPresetManager *_presetManager;
    NSArray <NSMenuItem *> *_defaultPresetMenuItems;
    SLHEncoderSettings *_encoderSettings;
    NSView *_encoderSettingsView;
    SLHEncoder *_encoder;
    SLHTextEditor *_textEditor;
    NSPopover *_popover;
    NSDictionary <NSString *, SLHMethodAddress *> *_observedPrefs;
    SLHEncoderHistory *_encoderHistory;
    SLHTrimViewController *_trimViewController;
    NSPopover *_trimViewSettingsPopover;
    SLHOutputNameController *_outputNameController;
    SLHTemplateNameFormatter *_templateNameFormatter;
    
    CGFloat _sideBarWidth;
    CGFloat _bottomBarHeight;
    CGFloat _encoderItemsViewWidth;

}

@property (nonatomic) SLHEncoderItem *currentEncoderItem;
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
    NSString *name = SLHPreferences.preferences.lastUsedFormatName;
    if (name) {
        [_formatsPopUp selectItemWithTitle:name];
    }
    
    [self formatsPopUpAction:_formatsPopUp];
    
    /* Drag and Drop support */
    [self.window registerForDraggedTypes:@[NSFilenamesPboardType]];
    
    /* MPVPlayer */
    
    SLHPreferences *appPrefs = SLHPreferences.preferences;
    self.preferences = appPrefs;
    
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
    
    /* SLHExternalPlayer */
    NSURL *mpvURL = [NSURL fileURLWithPath:appPrefs.mpvPath];
    NSURL *mpvConfURL = [NSURL fileURLWithPath:appPrefs.mpvConfigPath];
    [SLHExternalPlayer setDefaultPlayerURL:mpvURL];
    [SLHExternalPlayer setDefaultPlayerConfigURL:mpvConfURL];
    
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
    
    /* SLHTemplateNameFormatter */
    _templateNameFormatter = [[SLHTemplateNameFormatter alloc] init];
    _templateNameFormatter.templateFormat = _preferences.outputNameTemplate;
    
    /* NSApplication */
    [nc addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:NSApp];
}

#pragma mark - Methods

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
    NSString *extension = encoderItem.outputPath.pathExtension;
    NSString *fileName = encoderItem.playerItem.url.lastPathComponent.stringByDeletingPathExtension;
    encoderItem.outputFileName = [fileName stringByAppendingFormat:@"_%lu%02u.%@", time(0), arc4random_uniform(100), extension];
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
    _trimViewController.encoderItem = nil;
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
        NSLog(@"Cannot load %@\n %@", url, playerItem.error.localizedDescription);
        return NO;
    }
    if (![self hasMediaStreams:playerItem]) {
        NSLog(@"Cannot load %@\n File doesn't contain playable streams.", url);
        return NO;
    }
    [self createEncoderItemWith:playerItem];
    return YES;
}


- (void)createEncoderItemWith:(MPVPlayerItem *)playerItem {
    SLHEncoderItem *encoderItem = [[SLHEncoderItem alloc] initWithPlayerItem:playerItem];
    NSString *outputName = encoderItem.outputFileName;
    encoderItem.outputPath = [[self outputPathForSourcePath:playerItem.filePath] stringByAppendingPathComponent:outputName];
    
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
    SLHPreferences *prefs = [SLHPreferences preferences];
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


- (void)createDefaultPresetMenuItems {
    NSMenuItem *separator = [NSMenuItem separatorItem];
    NSMenuItem *managePresets = [[NSMenuItem alloc] initWithTitle:@"Manage Presets" action:@selector(showPresetsWindow:) keyEquivalent:@""];
    managePresets.target = _presetManager;
    NSMenuItem *savePreset = [[NSMenuItem alloc] initWithTitle:@"Save Preset" action:@selector(savePreset:) keyEquivalent:@""];
    savePreset.target = self;
    _defaultPresetMenuItems =  @[separator, savePreset, managePresets];
}

- (BOOL)createExternalPlayerWithMedia:(NSURL *)url {
    _externalPlayer = [SLHExternalPlayer defaultPlayer];
    if (_externalPlayer.error) {
        NSAlert *alert = [NSAlert new];
        alert.messageText = [NSString stringWithFormat:@"Cannot launch %@", SLHPreferences.preferences.mpvPath];
        alert.informativeText = _externalPlayer.error.localizedDescription;
        _externalPlayer = nil;
        [alert runModal];
        return NO;
    } else {
        _externalPlayer.url = url;
    }
    return YES;
}

#pragma mark - KVO

static char SLHPreferencesKVOContext;

- (void)screenshotFormatDidChange:(NSString *)newValue {
    [_player setString:newValue
           forProperty:MPVPlayerPropertyScreenshotFormat];
}

- (void)screenshotTemplateDidChange:(NSString *)newValue {
    [_player setString:newValue
           forProperty:MPVPlayerPropertyScreenshotTemplate];
}

- (void)screenshotPathDidChange:(NSString *)newValue {
    [_player setString:newValue
           forProperty:MPVPlayerPropertyScreenshotDirectory];
}

- (void)screenshotJPGQualityDidChange:(NSNumber *)newValue {
    [_player setInteger:newValue.integerValue
            forProperty:MPVPlayerPropertyScreenshotJPGQuality];
}

- (void)screenshotPNGCompressionDidChange:(NSNumber *)newValue {
    [_player setInteger:newValue.integerValue
            forProperty:MPVPlayerPropertyScreenshotPNGCompression];
}

- (void)osdFontNameDidChange:(NSString *)newValue {
    [_player setString:newValue forProperty:MPVPlayerPropertyOSDFontName];
}

- (void)osdFontSizeDidChange:(NSNumber *)newValue {
    [_player setInteger:newValue.integerValue forProperty:MPVPlayerPropertyOSDFontSize];
}

- (void)osdFontScaleByWindowDidChange:(NSNumber *)newValue {
    [_player setBool:newValue.boolValue forProperty:MPVPlayerPropertyOSDFontScaleByWindow];
}

- (void)subsFontNameDidChange:(NSString *)newValue {
    [_player setString:newValue forProperty:MPVPlayerPropertySubsFontName];
}

- (void)subsFontSizeDidChange:(NSNumber *)newValue {
    [_player setInteger:newValue.integerValue forProperty:MPVPlayerPropertySubsFontSize];
}

- (void)subsFontScaleByWindowDidChange:(NSNumber *)newValue {
    [_player setBool:newValue.boolValue forProperty:MPVPlayerPropertySubsFontScaleByWindow];
}

- (void)advancedOptionDidChange:(id)option {
    NSError *error = nil;
    if (![_player setString:[option valueForKey:SLHPreferencesAdvancedOptionValueKey]
                forProperty:[option valueForKey:SLHPreferencesAdvancedOptionNameKey]
                      error:&error]) {
        [self presentError:error];
    }
}

- (void)enableAdvancedOptionsDidChange:(NSNumber *)newValue {
    if (newValue.boolValue) {
        NSDictionary *advancedOptions = SLHPreferences.preferences.advancedOptions;
        if (advancedOptions.count) {
            __unsafe_unretained typeof(self) uself = self;
            __unsafe_unretained typeof(_player) player = _player;
            
            [advancedOptions enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                NSError *error = nil;
                if (![player setString:obj forProperty:key error:&error]) {
                    [uself presentError:error];
                }
            }];
        }
    }
}

- (void)updateWindowTitleStyle:(NSNumber *)obj {
    NSWindowTitleVisibility value = obj.integerValue;
    NSWindow *window = self.window;
    window.titleVisibility = value;
    if (_currentEncoderItem) {
        NSURL *url;
        NSString *title;
        if (value == NSWindowTitleVisible) {
            url = _currentEncoderItem.playerItem.url;
            title = url.lastPathComponent;
        } else {
            title = @"";
            url = nil;
        }
        window.representedURL = url;
        window.title = title;
    }
}

- (void)reloadExternalPlayer:(NSString *)obj {
    [SLHExternalPlayer setDefaultPlayerURL:[NSURL fileURLWithPath:obj
                                                      isDirectory:NO]];
    [SLHExternalPlayer reinitializeDefaultPlayer];
}

- (void)updateTemplateName:(NSString *)obj {
    _templateNameFormatter.templateFormat = obj;
}

- (void)observePreferences:(SLHPreferences *)appPrefs {
    _observedPrefs = @{
                       SLHPreferencesScreenshotPathKey           : addressOf(self, @selector(screenshotPathDidChange:)),
                       SLHPreferencesScreenshotFormatKey         : addressOf(self, @selector(screenshotFormatDidChange:)),
                       SLHPreferencesScreenshotTemplateKey       : addressOf(self, @selector(screenshotTemplateDidChange:)),
                       SLHPreferencesScreenshotJPGQualityKey     : addressOf(self, @selector(screenshotJPGQualityDidChange:)),
                       SLHPreferencesScreenshotPNGCompressionKey : addressOf(self, @selector(screenshotPNGCompressionDidChange:)),
                       SLHPreferencesOSDFontNameKey              : addressOf(self, @selector(osdFontNameDidChange:)),
                       SLHPreferencesOSDFontSizeKey              : addressOf(self, @selector(osdFontSizeDidChange:)),
                       SLHPreferencesOSDFontScaleByWindowKey     : addressOf(self, @selector(osdFontScaleByWindowDidChange:)),
                       SLHPreferencesSubtitlesFontNameKey              : addressOf(self, @selector(subsFontNameDidChange:)),
                       SLHPreferencesSubtitlesFontSizeKey              : addressOf(self, @selector(subsFontSizeDidChange:)),
                       SLHPreferencesSubtitlesFontScaleByWindowKey     : addressOf(self, @selector(subsFontScaleByWindowDidChange:)),
                       SLHPreferencesAdvancedOptionsLastEditedKey   : addressOf(self, @selector(advancedOptionDidChange:)),
                       SLHPreferencesAdvancedOptionsEnabledKey      : addressOf(self, @selector(enableAdvancedOptionsDidChange:)),
                       SLHPreferencesWindowTitleStyleKey    : addressOf(self, @selector(updateWindowTitleStyle:)),
                       SLHPreferencesMPVPathKey             : addressOf(self, @selector(reloadExternalPlayer:)),
                       SLHPreferencesOutputNameTemplateKey  : addressOf(self, @selector(updateTemplateName:))
                       };
    
    for (NSString *key in _observedPrefs) {
        [appPrefs addObserver:self
                   forKeyPath:key
                      options:NSKeyValueObservingOptionNew
                      context:&SLHPreferencesKVOContext];
    }
}

- (void)unobservePreferences:(SLHPreferences *)appPrefs {
    for (NSString *key in _observedPrefs) {
        [appPrefs removeObserver:self
                      forKeyPath:key
                         context:&SLHPreferencesKVOContext];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    if (context == &SLHPreferencesKVOContext) {
        SLHMethodAddress *method = _observedPrefs[keyPath];
        if (method) {
            ((SLHSetterIMP)method->_impl)(self, method->_selector, change[NSKeyValueChangeNewKey]);
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
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
    TimeInterval interval = _currentEncoderItem.interval;
    if (inMark > interval.end) {
        _currentEncoderItem.intervalEnd = outMark;
        _currentEncoderItem.intervalStart = inMark;
    } else {
        _currentEncoderItem.intervalStart = inMark;
        _currentEncoderItem.intervalEnd = outMark;
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
    
    SLHEncoderItem *duplicate = [self duplicateEncoderItem:_currentEncoderItem];
    
    duplicate.intervalEnd = end;
    duplicate.intervalStart = start;
    
    [_itemsArrayController insertObject:duplicate
                  atArrangedObjectIndex:[_itemsArrayController.arrangedObjects indexOfObject:_currentEncoderItem] + 1];
    
    [_player seekExactTo:start];
}

- (IBAction)resetSelection:(id)sender {
    _currentEncoderItem.intervalStart = 0;
    _currentEncoderItem.intervalEnd = _currentEncoderItem.playerItem.duration;
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
    if (!_externalPlayer) {
        if (![self createExternalPlayerWithMedia:_currentEncoderItem.playerItem.url]) {
            return;
        }
    } else {
        _externalPlayer.url = _currentEncoderItem.playerItem.url;
    }
    [_externalPlayer play];
    [_externalPlayer orderFront];

}

- (IBAction)previewSegment:(id)sender {
    SLHPlayerViewController *playerController = _playerView.viewController;
    TimeInterval interval = _currentEncoderItem.interval;
    [playerController loopPlaybackWithStart:interval.start end:interval.end];
}

- (IBAction)previewOutputFile:(id)sender {
    if (!_externalPlayer) {
        if (![self createExternalPlayerWithMedia:[NSURL fileURLWithPath:_lastEncodedMediaFilePath]]) {
            return;
        }
    } else {
        _externalPlayer.url = [NSURL fileURLWithPath:_lastEncodedMediaFilePath];
    }
    [_externalPlayer play];
    [_externalPlayer orderFront];
}

- (IBAction)addSelectionToQueue:(id)sender {
    NSEventModifierFlags flags = NSApp.currentEvent.modifierFlags;
    [self.window endEditingFor:nil];
    
    _currentEncoderItem.encoderArguments = [_formatsArrayController.selection valueForKey:@"arguments"];
    [_queue addEncoderItems:@[_currentEncoderItem]];
    
    if (flags & NSEventModifierFlagOption) {
        [self removeEncoderItem:sender];
    }
}

- (IBAction)addAllToQueue:(id)sender {
    NSEventModifierFlags flags = NSApp.currentEvent.modifierFlags;
    [self.window endEditingFor:nil];
    
    NSArray *items = _itemsArrayController.arrangedObjects;
    NSArray *formats = _formatsArrayController.arrangedObjects;
    
    for (SLHEncoderItem *i in items) {
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
    [self.window endEditingFor:nil];
    
    const NSEventModifierFlags
    shouldEditArgs = NSApp.currentEvent.modifierFlags & NSAlternateKeyMask;
    
    if (!_preferences.shouldOverwriteFiles &&
        [[NSFileManager defaultManager] fileExistsAtPath:_currentEncoderItem.outputPath
                                             isDirectory:nil])
    {
        NSString *question = @"Overwrite file?";
        NSString *info = [NSString stringWithFormat:@"File '%@' already exists.",
                          _currentEncoderItem.outputPath];
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
    
    _currentEncoderItem.encoderArguments = [_formatsArrayController.selection valueForKey:@"arguments"];
    
    if (shouldEditArgs) {
        SLHModalWindowController *win = [[SLHModalWindowController alloc] init];
        SLHArgumentsViewController *argsView = [[SLHArgumentsViewController alloc] init];
        win.title = @"Encoding Arguments";
        win.contentView = argsView.view;
        argsView.encoderItem = _currentEncoderItem;
        [win.window setFrame:NSMakeRect(0, 0, 360, 640) display:NO];
        [win runModal];
    }
     __unsafe_unretained typeof(self) obj = self;
    [_encoder encodeItem:_currentEncoderItem usingBlock:^(SLHEncoderState state) {
        switch (state)  {
                
            case SLHEncoderStateSuccess: {
                self.lastEncodedMediaFilePath = obj->_currentEncoderItem.outputPath;
                if (SLHPreferences.preferences.updateFileName) {
                    [self updateOutputFileName:sender];
                }
                
                NSString *log = obj->_encoder.encodingLog;
                [obj->_encoderHistory addItemWithPath:obj->_lastEncodedMediaFilePath log: log ? log : @""];
                
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
    
    NSString *extension = encoderItem.container;
    NSURL *sourceURL = encoderItem.playerItem.url;
    
    if (!extension) {
        extension = sourceURL.pathExtension;
    }

    NSString *outputName = sourceURL.lastPathComponent.stringByDeletingPathExtension;
    outputName = [outputName stringByAppendingFormat:@"_%lu%02u.%@", time(0), arc4random_uniform(100), extension];
    encoderItem.outputFileName = outputName;
}

- (IBAction)addEncoderItem:(id)sender {
    if (_currentEncoderItem) {
        SLHEncoderItem *encoderItem = [self duplicateEncoderItem:_currentEncoderItem];
        [_itemsArrayController insertObject:encoderItem
                      atArrangedObjectIndex:[_itemsArrayController.arrangedObjects indexOfObject:_currentEncoderItem] + 1];
        
        // Force Key-Value observer to update
        encoderItem.intervalStart = _currentEncoderItem.interval.start;
        
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

- (IBAction)textEditorDone:(id)sender {
    NSString *outPath = _textEditor.textView.string.copy;
    SLHEncoderItem *encoderItem = _textEditor.representedObject;
    
    [encoderItem willChangeValueForKey:@"outputFileName"];
    {
        encoderItem.outputPath = outPath;
    }
    [encoderItem didChangeValueForKey:@"outputFileName"];
    
    [_popover close];
    _textEditor.representedObject = nil;
}

- (IBAction)textEditorCancel:(id)sender {
     [_popover close];
    _textEditor.representedObject = nil;
}

- (IBAction)showTextEditor:(NSButton *)sender {
    
    if (!_popover) {
        _textEditor = SLHTextEditor.new;
        NSRect frame = NSMakeRect(0, 0, 500, 200);
        _textEditor.view.frame = frame;
        NSButton *button = _textEditor.doneButton;
        button.action = @selector(textEditorDone:);
        button.target = self;
        button = _textEditor.cancelButton;
        button.action = @selector(textEditorCancel:);
        button.target = self;
        _popover = NSPopover.new;
        _popover.contentViewController = _textEditor;
    }
    
    NSTableCellView *tableCell = (id)sender.superview;
    SLHEncoderItem *encoderItem = tableCell.objectValue;
    _textEditor.representedObject = encoderItem;
    NSString *outPath = encoderItem.outputPath;
    _textEditor.textView.string = outPath;
    [_popover showRelativeToRect:sender.frame ofView:sender.superview preferredEdge:NSMinYEdge];

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
        NSTableCellView *tableCell = (id)sender.superview;
        SLHEncoderItem *encoderItem = tableCell.objectValue;
        NSString *outname = encoderItem.outputPath.lastPathComponent;
        encoderItem.outputPath = [NSString stringWithFormat:@"%@/%@", path, outname];
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
    
    [_player seekExactTo:_currentEncoderItem.interval.start];
    [self matchVideoStreamsToEncoderItem:_currentEncoderItem];
    [_player pause];
}

#pragma mark - NSApplication Notifications

- (void)applicationWillTerminate:(NSNotification *)n {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    SLHPreferences.preferences.lastUsedFormatName = _formatsPopUp.selectedItem.title;
    if (_presetManager.hasChanges) {
        [_presetManager savePresets];
    }
    [self unobservePreferences:SLHPreferences.preferences];
    [_player shutdown];
    _player = nil;
    self.currentEncoderItem = nil;
    [_itemsArrayController removeObjects:_itemsArrayController.arrangedObjects];
}

#pragma mark - NSDraggingDestination

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    NSPasteboard *pboard;
    pboard = [sender draggingPasteboard];
    
    if ([pboard.types containsObject:NSFilenamesPboardType]) {
        return NSDragOperationGeneric;
    }
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    NSPasteboard *pboard;
    BOOL result = NO;
    pboard = [sender draggingPasteboard];

    if ([pboard.types containsObject:NSFilenamesPboardType]) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        NSString * path = files.firstObject;
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
    if (encoderItem == _currentEncoderItem) {
        return;
    }
    
    [_formatsArrayController setSelectionIndex:encoderItem.tag];
    SLHEncoderBaseFormat *fmt = _formatsArrayController.selectedObjects.firstObject;
    fmt.encoderItem = encoderItem;
    _encoderSettings.delegate = fmt;
    
    MPVPlayer *player = _player;
    MPVPlayerItem *playerItem = encoderItem.playerItem;
    if (playerItem != _currentEncoderItem.playerItem) {
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
    _trimViewController.encoderItem = _currentEncoderItem;
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
        return 180; // minimum width of encoder items table
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
