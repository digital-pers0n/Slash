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
#import "SLHTrimView.h"
#import "SLHPresetManager.h"
#import "SLHEncoderQueue.h"
#import "SLHExternalPlayer.h"
#import "SLHPlayerViewController.h"
#import "SLHMethodAddress.h"

#import "MPVPlayer.h"
#import "MPVPlayerItem.h"
#import "MPVPlayerItemTrack.h"
#import "MPVPlayerProperties.h"

#import "SLHEncoderVP9Format.h"
#import "SLHEncoderVPXFormat.h"
#import "SLHEncoderX264Format.h"
#import "SLHEncoderUniversalFormat.h"

extern NSString *const SLHEncoderFormatDidChangeNotification;

@interface SLHWindowController () <NSSplitViewDelegate, NSWindowDelegate, NSDraggingDestination, NSTableViewDelegate, SLHTrimViewDelegate, NSMenuDelegate, SLHPresetManagerDelegate> {
    IBOutlet SLHPlayerView *_playerView;
    IBOutlet NSView *_sbView;
    IBOutlet NSView *_bottomBarView;
    IBOutlet NSArrayController *_itemsArrayController;
    IBOutlet NSArrayController *_formatsArrayController;
    IBOutlet NSSplitView *_inspectorSplitView;
    IBOutlet NSSplitView *_videoSplitView;
    
    IBOutlet NSPopUpButton *_videoStreamPopUp;
    IBOutlet NSPopUpButton *_audioStreamPopUp;
    IBOutlet NSPopUpButton *_subtitlesStreamPopUp;
    IBOutlet NSPopUpButton *_formatsPopUp;
    
    MPVPlayer *_player;
    SLHExternalPlayer *_externalPlayer;
    SLHPresetManager *_presetManager;
    NSArray <NSMenuItem *> *_defaultPresetMenuItems;
    SLHEncoderSettings *_encoderSettings;
    NSView *_encoderSettingsView;
    SLHEncoder *_encoder;
    SLHTextEditor *_textEditor;
    NSPopover *_popover;
    NSDictionary <NSString *, SLHMethodAddress *> *_observedPrefs;
    
    CGFloat _sideBarWidth;
    CGFloat _bottomBarHeight;
    
    double _savedTimePosition;

    struct _trimViewFlags {
        unsigned int needsUpdateStartValue:1;
        unsigned int shouldStop:1;
    } _TVFlags;
}

@property (nonatomic) SLHEncoderItem *currentEncoderItem;
@property (nonatomic, nullable) NSString *lastEncodedMediaFilePath;

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
    MPVPlayer *player = [[MPVPlayer alloc] init];
    
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
    SLHPreferences *appPrefs = SLHPreferences.preferences;
    
    [player setString:appPrefs.screenshotTemplate
          forProperty:MPVPlayerPropertyScreenshotTemplate];
    
    [player setString:appPrefs.screenshotPath
          forProperty:MPVPlayerPropertyScreenshotDirectory];
    
    [player setString:appPrefs.screenshotFormat
          forProperty:MPVPlayerPropertyScreenshotFormat];
    [self observePreferences:appPrefs];
    
    /* SLHExternalPlayer */
    NSURL *mpvURL = [NSURL fileURLWithPath:appPrefs.mpvPath];
    NSURL *mpvConfURL = [NSURL fileURLWithPath:appPrefs.mpvConfigPath];
    [SLHExternalPlayer setDefaultPlayerURL:mpvURL];
    [SLHExternalPlayer setDefaultPlayerConfigURL:mpvConfURL];

}

#pragma mark - Methods

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

static inline SLHMethodAddress *addressOf(id target, SEL action) {
    return [SLHMethodAddress methodAddressWithTarget:target selector:action];
}

- (void)observePreferences:(SLHPreferences *)appPrefs {
    _observedPrefs = @{
                       SLHPreferencesScreenshotPathKey     : addressOf(self, @selector(screenshotPathDidChange:)),
                       SLHPreferencesScreenshotFormatKey   : addressOf(self, @selector(screenshotFormatDidChange:)),
                       SLHPreferencesScreenshotTemplateKey : addressOf(self, @selector(screenshotTemplateDidChange:))
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

typedef void (*basic_imp)(id, SEL, id);

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    if (context == &SLHPreferencesKVOContext) {
        SLHMethodAddress *method = _observedPrefs[keyPath];
        if (method) {
            ((basic_imp)method->_impl)(self, method->_selector, change[NSKeyValueChangeNewKey]);
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
         [_player printOSDMessage:[NSString stringWithFormat:@"OSD: %li", level]];
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
}

- (IBAction)jumpToEndPosition:(id)sender {
    _player.timePosition = _currentEncoderItem.interval.end;
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
        [_externalPlayer orderFront];
    }
    [_externalPlayer play];
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
        [_externalPlayer orderFront];
    }
    [_externalPlayer play];
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
    _currentEncoderItem.encoderArguments = [_formatsArrayController.selection valueForKey:@"arguments"];
    
    if (NSApp.currentEvent.modifierFlags & NSAlternateKeyMask) {
        SLHModalWindowController *win = [[SLHModalWindowController alloc] init];
        SLHArgumentsViewController *argsView = [[SLHArgumentsViewController alloc] init];
        win.title = @"Encoding Arguments";
        win.contentView = argsView.view;
        argsView.encoderItem = _currentEncoderItem;
        [win.window setFrame:NSMakeRect(0, 0, 360, 640) display:NO];
        [win runModal];
    }
    
    [_encoder encodeItem:_currentEncoderItem usingBlock:^(SLHEncoderState state) {
        switch (state)  {
                
            case SLHEncoderStateSuccess: {
                self.lastEncodedMediaFilePath = _currentEncoderItem.outputPath;
                if (SLHPreferences.preferences.updateFileName) {
                    [self updateOutputFileName:sender];
                }
                break;
            }
                
            case SLHEncoderStateFailed: {
                NSString *log = _encoder.encodingLog;
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
        [_encoder.window performClose:nil];
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

- (void)playerDidRestartPlayback:(NSNotification *)n {
    
    if (_TVFlags.shouldStop) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MPVPlayerDidStartSeekNotification object:_player];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MPVPlayerDidRestartPlaybackNotification object:_player];
        if (_TVFlags.needsUpdateStartValue) {
            _currentEncoderItem.intervalStart = _player.timePosition;
            
        } else {
            _currentEncoderItem.intervalEnd = _player.timePosition;
        }
        _player.timePosition = _savedTimePosition;
        _TVFlags.shouldStop = 0;
        return;
    }
    
    double time = 0;
    if (_TVFlags.needsUpdateStartValue) {
        time = _currentEncoderItem.interval.start;
    } else {
        time = _currentEncoderItem.interval.end;
    }
    _player.timePosition = time;
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
        
        self.currentEncoderItem = encoderItem;
        player.currentItem = playerItem;
        [player pause];
        [self populatePopUpMenus:playerItem];
        [self updateWindowTitle:playerItem.url];
        [self updatePopUpMenus:encoderItem];
    
    } else {
        
        self.currentEncoderItem = encoderItem;
        [self updatePopUpMenus:encoderItem];
        [self matchVideoStreamsToEncoderItem:encoderItem];
    }
}

#pragma mark - SLHTrimViewDelegate

- (void)trimViewMouseDown:(SLHTrimView *)trimView {
    [trimView unbind:@"startValue"];
    [trimView unbind:@"endValue"];

    NSTableCellView *tcv = (id)trimView.superview;
    SLHEncoderItem *encoderItem = tcv.objectValue;
    if (encoderItem != _currentEncoderItem) {
        [_itemsArrayController setSelectedObjects:@[encoderItem]];
        _savedTimePosition = encoderItem.interval.start;
    } else {
        _savedTimePosition = _player.timePosition;
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerDidRestartPlayback:) name:MPVPlayerDidRestartPlaybackNotification object:_player];

}

- (void)trimViewMouseDownStartPosition:(SLHTrimView *)trimView {
    _TVFlags.needsUpdateStartValue = 1;
    _player.timePosition = trimView.startValue;
}

- (void)trimViewMouseDownEndPosition:(SLHTrimView *)trimView {
    _TVFlags.needsUpdateStartValue = 0;
    _player.timePosition = trimView.endValue;
}

- (void)trimViewMouseDraggedStartPosition:(SLHTrimView *)trimView {
    _currentEncoderItem.intervalStart = trimView.startValue;
}

- (void)trimViewMouseDraggedEndPosition:(SLHTrimView *)trimView {
   _currentEncoderItem.intervalEnd = trimView.endValue;
}

- (void)trimViewMouseUp:(SLHTrimView *)trimView {
    if (_TVFlags.needsUpdateStartValue) {
        _player.timePosition = trimView.startValue;
    } else {
        _player.timePosition = trimView.endValue;
    }
    _TVFlags.shouldStop = 1;
    
    [trimView bind:@"startValue" toObject:_currentEncoderItem withKeyPath:@"intervalStart" options:nil];
    [trimView bind:@"endValue" toObject:_currentEncoderItem withKeyPath:@"intervalEnd" options:nil];
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

- (void)windowWillClose:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    SLHPreferences.preferences.lastUsedFormatName = _formatsPopUp.selectedItem.title;
    if (_presetManager.hasChanges) {
        [_presetManager savePresets];
    }
    [self unobservePreferences:SLHPreferences.preferences];
    [_player shutdown];
    _player = nil;
}

- (void)windowWillStartLiveResize:(NSNotification *)notification {
    _sideBarWidth = NSWidth(_encoderSettingsView.frame);
    _bottomBarHeight = NSHeight(_bottomBarView.frame);
}

- (void)windowWillEnterFullScreen:(NSNotification *)notification {
    _sideBarWidth = NSWidth(_encoderSettingsView.frame);
    _bottomBarHeight = NSHeight(_bottomBarView.frame);
}

- (void)windowWillExitFullScreen:(NSNotification *)notification {
    _sideBarWidth = NSWidth(_encoderSettingsView.frame);
    _bottomBarHeight = NSHeight(_bottomBarView.frame);
}

#pragma mark - NSSplitViewDelegate

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {
    if (subview == _encoderSettings.view) {
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
    }
    return NSHeight(splitView.frame) - 100; // minimum bottomBar height
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex {
    if (splitView == _inspectorSplitView) {
        return NSWidth(splitView.frame) - 280;
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
