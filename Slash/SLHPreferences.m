//
//  SLHPreferences.m
//  Slash
//
//  Created by Terminator on 9/28/18.
//  Copyright © 2018 digital-pers0n. All rights reserved.
//

#import "SLHPreferences.h"
#import "SLHPreferencesKeys.h"

extern NSString *const SLHPreferencesDefaultOutputPath;
extern NSString *const SLHPreferencesNumberOfThreadsKey;
extern NSString *const SLHPreferencesUpdateOutputNameKey;
extern NSString *const SLHPreferencesLastUsedFormatKey;
extern NSString *const SLHPreferencesDefaultFFMpegPath;
extern NSString *const SLHPreferencesDefaultMPVPath;

extern NSString * const SLHPreferencesDefaultScreenshotPath;
extern NSString * const SLHPreferencesDefaultScreenshotFormat;
extern NSString * const SLHPreferencesDefaultScreenshotTemplate;
extern NSString * const SLHPreferencesScreenshotPathKey;
extern NSString * const SLHPreferencesScreenshotFormatKey;
extern NSString * const SLHPreferencesScreenshotTemplateKey;

static NSString * const  SLHPreferencesDefaultFontName  =  @"Helvetica";
static NSString * const  SLHPreferencesLastSelectedPrefTagKey = @"lastSelectedPrefTag";

typedef NS_ENUM(NSInteger, SLHPreferencesToolbarItemTag) {
    SLHPreferencesGeneralToolbarItem = 0,
    SLHPreferencesMPVToolbarItem,
    SLHPreferencesAdvancedToolbarItem
};

#define SLHPreferencesDefaultPNGCompression     7
#define SLHPreferencesDefaultJPGQuality         90

@interface SLHPreferences () <NSWindowDelegate> {
    
    IBOutlet NSPopUpButton *_outputPathPopUp;
    IBOutlet NSPopUpButton *_screenshotFormatPopUp;
    IBOutlet NSToolbar *_toolbar;
    IBOutlet NSView *_generalPrefsView;
    IBOutlet NSView *_mpvPrefsView;
    IBOutlet NSView *_advancedPrefsView;
    IBOutlet NSDictionaryController *_dictionaryController;
    
    __weak NSView *_currentPrefsView;
    
    NSMutableArray <NSString *> *_recentOutputPaths;
    NSString *_currentOutputPath;
    
    NSString *_mpvConfigPath;
    NSString *_mpvLuaScriptPath;
    
    NSString *_appSupportPath;
}

@property  NSUserDefaults *userDefaults;

@property IBOutlet NSTextField *ffmpegPathTextField;
@property IBOutlet NSTextField *mpvPathTextField;
@property (nonatomic) id lastEditedAdvancedOption;

@end

@implementation SLHPreferences

+ (instancetype)preferences {
    static dispatch_once_t onceToken = 0;
    static SLHPreferences *result = nil;
    dispatch_once(&onceToken, ^{
        result = [[SLHPreferences alloc] init];
    });
    return result;
}

- (NSString *)windowNibName {
    return self.className;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        [self setUpPaths];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        
        _userDefaults = userDefaults;
        
        id obj = [userDefaults objectForKey:SLHPreferencesNumberOfThreadsKey];
        if (obj) {
           _numberOfThreads = ((NSNumber *)obj).unsignedIntegerValue;
        } else {
            _numberOfThreads = NSProcessInfo.processInfo.processorCount;
            [userDefaults setInteger:_numberOfThreads forKey:SLHPreferencesNumberOfThreadsKey];
        }
        obj = [userDefaults objectForKey:SLHPreferencesUpdateOutputNameKey];
        if (obj) {
            _updateFileName = ((NSNumber *)obj).boolValue;
        } else {
            [userDefaults setBool:YES forKey:SLHPreferencesUpdateOutputNameKey];
        }
        
        _recentOutputPaths = [userDefaults arrayForKey:SLHPreferencesRecentOutputPaths].mutableCopy;
        if (!_recentOutputPaths) {
            _recentOutputPaths = [[NSMutableArray alloc] init];
        }
        
        if (_recentOutputPaths.count) {
            _currentOutputPath = _recentOutputPaths[0];
        } else {
            _currentOutputPath = [SLHPreferencesDefaultOutputPath stringByExpandingTildeInPath];
        }
        
        if (!self.ffmpegPath) {
            self.ffmpegPath = SLHPreferencesDefaultFFMpegPath;
        }

        if (!self.mpvPath) {
            self.mpvPath = SLHPreferencesDefaultMPVPath;
        }
        
        if (!self.screenshotPath) {
            self.screenshotPath = SLHPreferencesDefaultScreenshotPath;
        }
        
        if (!self.screenshotFormat) {
            self.screenshotFormat = SLHPreferencesDefaultScreenshotFormat;
        }
        
        if (!self.screenshotTemplate) {
            self.screenshotTemplate = SLHPreferencesDefaultScreenshotTemplate;
        }
        
        if (![_userDefaults valueForKey:SLHPreferencesScreenshotJPGQualityKey]) {
            self.screenshotJPGQuality = SLHPreferencesDefaultJPGQuality;
        }
        
        if (![_userDefaults valueForKey:SLHPreferencesScreenshotPNGCompressionKey]) {
            self.screenshotPNGCompression = SLHPreferencesDefaultPNGCompression;
        }
        
        if (!self.osdFontName) {
            self.osdFontName = SLHPreferencesDefaultFontName;
            self.osdFontSize = 40;
            self.osdFontScaleByWindow = NO;
        }
        
        if (!self.subtitlesFontName) {
            self.subtitlesFontName = SLHPreferencesDefaultFontName;
            self.subtitlesFontSize = 40;
            self.subtitlesFontScaleByWindow = NO;
        }
        
        if (!self.advancedOptions) {
            [_userDefaults setObject:@{} forKey:SLHPreferencesAdvancedOptionsKey];
        }
        
    }
    return self;
}

- (void)setUpPaths {
    NSError *error = nil;
    NSFileManager *fm = NSFileManager.defaultManager;
    NSString *path = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0];
    if (!path) {
        NSLog(@"Error: Cannot find Application Support Directory.");
        goto fatal_error;
    }
    path = [path stringByAppendingPathComponent:@"Slash"];
    if (![fm fileExistsAtPath:path isDirectory:nil]) {
        [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"Error: Cannot create '%@' directory.", path);
            goto fatal_error;
        }
    }
    _appSupportPath = path;
    
    _mpvConfigPath = [[NSBundle mainBundle] pathForResource:@"mpv" ofType:@"conf"];
    _mpvLuaScriptPath = [[NSBundle mainBundle] pathForResource:@"script" ofType:@"lua"];
    if (!_mpvConfigPath || !_mpvLuaScriptPath) {
        NSLog(@"Error: Cannot load resources.");
        goto fatal_error;
    }
    
    return;
    
fatal_error:
    
    {
        NSAlert *alert;
        if (error) {
            alert = [NSAlert alertWithError:error];
        } else {
            alert = [NSAlert alertWithMessageText:@"Initialization Failed." defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@"Aborting..."];
            
        }
        [alert runModal];
        exit(EXIT_FAILURE);
    }
    
    return;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    NSMenu *menu = _outputPathPopUp.menu;
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"Select Output Path..." action:@selector(selectOutputPath:) keyEquivalent:@""];
    item.tag = 200;
    item.target = self;
    [menu addItem:item];
    
    item = [[NSMenuItem alloc] initWithTitle:@"Restore Default" action:@selector(restoreDefaultOutputPath:) keyEquivalent:@""];
    item.tag = 201;
    item.target = self;
    [menu addItem:item];
    
    item = [[NSMenuItem alloc] initWithTitle:@"Clear Recent Paths" action:@selector(clearRecentPaths:) keyEquivalent:@""];
    item.tag = 202;
    item.target = self;
    [menu addItem:item];
    
    item = [NSMenuItem separatorItem];
    item.tag = 203;
    [menu addItem:item];
    
    if (_recentOutputPaths.count) {
        for (NSString *path in _recentOutputPaths) {
            item = [menu addItemWithTitle:path.lastPathComponent action:@selector(setOutputPath:) keyEquivalent:@""];
            item.target = self;
            item.representedObject = path;
            item.tag = 100;
            item.toolTip = path;
        }
        [_outputPathPopUp selectItemAtIndex:[menu indexOfItemWithTag:203] + 1];
    }
    
    [_screenshotFormatPopUp selectItemWithTitle:self.screenshotFormat];
    
    SLHPreferencesToolbarItemTag tag = [_userDefaults integerForKey:SLHPreferencesLastSelectedPrefTagKey];
    _toolbar.selectedItemIdentifier = _toolbar.visibleItems[tag].itemIdentifier;
    switch (tag) {
    
        case SLHPreferencesMPVToolbarItem:
            [self.window setContentSize:_mpvPrefsView.frame.size];
            [self showPrefsView:_mpvPrefsView];
            break;
        case SLHPreferencesAdvancedToolbarItem:
            [self showPrefsView:_advancedPrefsView];
            break;
        case SLHPreferencesGeneralToolbarItem:
        default:
            [self showPrefsView:_generalPrefsView];
            break;
    }
    
}

- (BOOL)outputPathSameAsInput {
    return [_userDefaults boolForKey:@"outputPathSameAsInput"];
}

- (void)setOutputPathSameAsInput:(BOOL)value {
    [_userDefaults setBool:value forKey:@"outputPathSameAsInput"];
}

- (NSString *)ffmpegPath {
    return [_userDefaults objectForKey:SLHPreferencesFFMpegFilePathKey];
}

- (void)setFfmpegPath:(NSString *)ffmpegPath {
    [_userDefaults setObject:ffmpegPath forKey:SLHPreferencesFFMpegFilePathKey];
}

- (NSString *)mpvPath {
    return [_userDefaults objectForKey:SLHPreferencesMPVFilePathKey];
}

- (void)setMpvPath:(NSString *)mpvPath {
    [_userDefaults setObject:mpvPath forKey:SLHPreferencesMPVFilePathKey];
}

- (void)setLastUsedFormatName:(NSString *)lastUsedFormatName {
    [_userDefaults setObject:lastUsedFormatName forKey:SLHPreferencesLastUsedFormatKey];
}

- (NSString *)lastUsedFormatName {
    return [_userDefaults objectForKey:SLHPreferencesLastUsedFormatKey];
}

- (void)setScreenshotPath:(NSString *)screenshotPath {
    [_userDefaults setObject:screenshotPath forKey:SLHPreferencesScreenshotPathKey];
}

- (NSString *)screenshotPath {
   return [_userDefaults stringForKey:SLHPreferencesScreenshotPathKey];
}

- (void)setScreenshotFormat:(NSString *)screenshotFormat {
    [_userDefaults setObject:screenshotFormat forKey:SLHPreferencesScreenshotFormatKey];
}

- (NSString *)screenshotFormat {
    return [_userDefaults stringForKey:SLHPreferencesScreenshotFormatKey];
}

- (void)setScreenshotTemplate:(NSString *)screenshotTemplate {
    [_userDefaults setObject:screenshotTemplate forKey:SLHPreferencesScreenshotTemplateKey];
}

- (NSString *)screenshotTemplate {
    return [_userDefaults stringForKey:SLHPreferencesScreenshotTemplateKey];
}

- (void)setScreenshotJPGQuality:(NSInteger)screenshotJPGQuality {
    [_userDefaults setInteger:screenshotJPGQuality forKey:SLHPreferencesScreenshotJPGQualityKey];
}

- (NSInteger)screenshotJPGQuality {
    return [_userDefaults integerForKey:SLHPreferencesScreenshotJPGQualityKey];
}

- (void)setScreenshotPNGCompression:(NSInteger)screenshotPNGCompression {
    [_userDefaults setInteger:screenshotPNGCompression forKey:SLHPreferencesScreenshotPNGCompressionKey];
}

- (NSInteger)screenshotPNGCompression {
    return [_userDefaults integerForKey:SLHPreferencesScreenshotPNGCompressionKey];
}

- (void)setOsdFontName:(NSString *)osdFontName {
    if (!osdFontName) {
        osdFontName = SLHPreferencesDefaultFontName;
    }
    [_userDefaults setObject:osdFontName forKey:SLHPreferencesOSDFontNameKey];
}

- (NSString *)osdFontName {
    return [_userDefaults objectForKey:SLHPreferencesOSDFontNameKey];
}

- (void)setOsdFontSize:(NSInteger)osdFontSize {
    [_userDefaults setInteger:osdFontSize forKey:SLHPreferencesOSDFontSizeKey];
}

- (NSInteger)osdFontSize {
    return [_userDefaults integerForKey:SLHPreferencesOSDFontSizeKey];
}

- (void)setOsdFontScaleWithWindow:(BOOL)osdFontScaleWithWindow {
    [_userDefaults setBool:osdFontScaleWithWindow forKey:SLHPreferencesOSDFontScaleByWindowKey];
}

- (BOOL)osdFontScaleWithWindow {
    return [_userDefaults boolForKey:SLHPreferencesOSDFontScaleByWindowKey];
}

- (void)setSubtitlesFontName:(NSString *)subtitlesFontName {
    if (!subtitlesFontName) {
        subtitlesFontName = SLHPreferencesDefaultFontName;
    }
    [_userDefaults setObject:subtitlesFontName forKey:SLHPreferencesSubtitlesFontNameKey];
}

- (NSString *)subtitlesFontName {
    return [_userDefaults objectForKey:SLHPreferencesSubtitlesFontNameKey];
}

- (void)setSubtitlesFontSize:(NSInteger)subtitlesFontSize {
     [_userDefaults setInteger:subtitlesFontSize forKey:SLHPreferencesSubtitlesFontSizeKey];
}

- (NSInteger)subtitlesFontSize {
    return [_userDefaults integerForKey:SLHPreferencesSubtitlesFontSizeKey];
}

- (void)setSubtitlesFontScaleWithWindow:(BOOL)subtitlesFontScaleWithWindow {
    [_userDefaults setBool:subtitlesFontScaleWithWindow forKey:SLHPreferencesSubtitlesFontScaleByWindowKey];
}

- (BOOL)subtitlesFontScaleWithWindow {
    return [_userDefaults boolForKey:SLHPreferencesSubtitlesFontScaleByWindowKey];
}

- (void)setEnableAdvancedOptions:(BOOL)enableAdvancedOptions {
    [_userDefaults setBool:enableAdvancedOptions forKey:SLHPreferencesAdvancedOptionsEnabledKey];
}

- (BOOL)enableAdvancedOptions {
    return [_userDefaults boolForKey:SLHPreferencesAdvancedOptionsEnabledKey];
}

- (NSDictionary *)advancedOptions {
    return [_userDefaults objectForKey:SLHPreferencesAdvancedOptionsKey];
}

- (void)showPrefsView:(NSView *)view {
    if (view == _currentPrefsView) {
        return;
    }
    
    NSWindow *window = self.window;
    if (![window makeFirstResponder:window]) {
        NSBeep();
        return;
    }
    NSSize currentSize = window.contentView.frame.size;
    
    NSSize newSize = view.frame.size;
    NSRect windowFrame = window.frame;
    CGFloat deltaH = newSize.height - currentSize.height;
    CGFloat deltaW = newSize.width - currentSize.width;
    windowFrame.size.height += deltaH;
    windowFrame.size.width += deltaW;
    windowFrame.origin.y -= deltaH;
    
    [_currentPrefsView removeFromSuperview];
    [window setFrame:windowFrame display:YES animate:YES];
    [window.contentView addSubview:view];
    _currentPrefsView = view;
    self.window.title = _toolbar.selectedItemIdentifier;
}

#pragma mark - IBActions

- (IBAction)didEndEditingValue:(id)sender {
    self.lastEditedAdvancedOption  = _dictionaryController.selection;
}

- (IBAction)showGeneralPrefs:(id)sender {
    [self showPrefsView:_generalPrefsView];
}

- (IBAction)showMPVPrefs:(id)sender {
    [self showPrefsView:_mpvPrefsView];
}

- (IBAction)showAdvancedPrefs:(id)sender {
    [self showPrefsView:_advancedPrefsView];
}

- (IBAction)selectFile:(NSButton *)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    if ([panel runModal] == NSModalResponseOK) {
        NSString *value = panel.URLs.firstObject.path;
        [_userDefaults setValue:value forKey:sender.identifier];
        switch (sender.tag) {
            case 1:
                _ffmpegPathTextField.stringValue = value;
                break;
            case 3:
                _mpvPathTextField.stringValue = value;
                break;
                
            default:
                break;
        }
    }
    
}

- (IBAction)selectOutputPath:(NSMenuItem *)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = NO;
    panel.canChooseFiles = NO;
    panel.canChooseDirectories = YES;
    panel.canCreateDirectories = YES;
    
    if ([panel runModal] == NSModalResponseOK) {
        NSMenu *menu = sender.menu;
        NSString *path = panel.URL.path;
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[path lastPathComponent] action:@selector(setOutputPath:) keyEquivalent:@""];
        item.tag = 100;
        item.target = self;
        item.representedObject = path;
        item.toolTip = path;
        [menu insertItem:item atIndex:[menu indexOfItemWithTag:203] + 1];
        [_outputPathPopUp selectItem:item];
        [_recentOutputPaths insertObject:path atIndex:0];
        _currentOutputPath = path;
        
    }
}

- (IBAction)setOutputPath:(NSMenuItem *)sender {
    NSString *path = sender.representedObject;
    NSMenu *menu = sender.menu;
    
    [menu removeItem:sender];
    [menu insertItem:sender atIndex:[menu indexOfItemWithTag:203] + 1];
    [_outputPathPopUp selectItem:sender];
    [_recentOutputPaths removeObject:path];
    [_recentOutputPaths insertObject:path atIndex:0];
    _currentOutputPath = path;
}

- (IBAction)clearRecentPaths:(NSMenuItem *)sender {
    NSMenu *menu = sender.menu;
    NSArray *items = menu.itemArray.copy;
    for (NSMenuItem *item in items) {
        if (item.tag == 100) {
            [_recentOutputPaths removeObject:item.representedObject];
            [menu removeItem:item];
        }
    }
    _currentOutputPath = [SLHPreferencesDefaultOutputPath stringByExpandingTildeInPath];
    [_outputPathPopUp selectItemAtIndex:0];
}

- (IBAction)restoreDefaultOutputPath:(id)sender {
    _currentOutputPath = [SLHPreferencesDefaultOutputPath stringByExpandingTildeInPath];
    [_outputPathPopUp selectItemAtIndex:0];
}

- (IBAction)updateNumberOfThreads:(NSTextField *)sender {
    
    _numberOfThreads = sender.integerValue;
}

- (IBAction)updateFileNameDidChange:(NSButton *)sender {
    _updateFileName = (sender.state);
}

- (IBAction)selectScreenshotSavePath:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = NO;
    panel.canChooseFiles = NO;
    panel.canChooseDirectories = YES;
    panel.canCreateDirectories = YES;
    
    if ([panel runModal] == NSModalResponseOK) {
        self.screenshotPath = panel.URL.path;
    }
}

- (IBAction)resetoreDefaultScreenshotTemplate:(id)sender {
    self.screenshotTemplate = SLHPreferencesDefaultScreenshotTemplate;
}

- (IBAction)updateScreenshotFormat:(id)sender {
    self.screenshotFormat = _screenshotFormatPopUp.selectedItem.title;
}

#pragma mark - NSWindowDelegate 

- (void)windowWillClose:(NSNotification *)notification {
    [_userDefaults setObject:_recentOutputPaths forKey:SLHPreferencesRecentOutputPaths];
    
    SLHPreferencesToolbarItemTag tag = SLHPreferencesGeneralToolbarItem;
    if (_currentPrefsView == _mpvPrefsView) {
        tag = SLHPreferencesMPVToolbarItem;
    }
    [_userDefaults setInteger:tag forKey:SLHPreferencesLastSelectedPrefTagKey];
}

@end
