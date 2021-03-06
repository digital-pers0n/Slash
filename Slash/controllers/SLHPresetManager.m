//
//  SLHPresetEditor.m
//  Slash
//
//  Created by Terminator on 2019/05/25.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHPresetManager.h"
#import "SLHPreferences.h"
#import "SLHPresetNameDialog.h"
#import "MPVKitDefines.h"
#import "NSDictionary+SLHPropertyListAddtions.h"

@interface SLHPresetManager () <NSTableViewDelegate, NSWindowDelegate, NSTextFieldDelegate> {
    NSMutableDictionary *_presets;
    NSString *_presetsPath;
    BOOL _hasWindow;
    BOOL _hasChanges;
    
    IBOutlet NSArrayController *_groupsController;
    IBOutlet NSArrayController *_presetsController;
    IBOutlet NSTableView *_groupsTableView;
    IBOutlet NSTableView *_presetsTableView;
}

@property NSMutableDictionary *presets;
@property (readonly) NSArray *groupsArray;
@property NSArray *presetsArray;

- (BOOL)writePresetsToURL:(NSURL *)url OBJC_DIRECT;
- (NSDictionary *)readPresetsFromURL:(NSURL *)url OBJC_DIRECT;

@end

@implementation SLHPresetManager

- (instancetype)init
{
    NSString *presetsPath = [SLHPreferences.preferences.appSupportPath stringByAppendingPathComponent:@"presets.dict"];
    return [self initWithPresetsPath:presetsPath];
    
}

- (instancetype)initWithPresetsPath:(NSString *)path {
    self = [super init];
    if (self) {
        NSURL *url = [NSURL fileURLWithPath:path isDirectory:NO];
        NSMutableDictionary *presets;
        presets = [[NSDictionary dictionaryWithContentsOfURL:url
                                                       error:nil] mutableCopy];
        if (!presets) {
            presets = NSMutableDictionary.new;
        }
        _presets = presets;
        _presetsPath = path.copy;
        _hasWindow = NO;
    }
    return self;
}

- (NSString *)windowNibName {
    return self.className;
}

- (void)windowDidLoad {
    [super windowDidLoad];
}

#pragma mark - Methods

- (NSArray<NSDictionary *> *)presetsForName:(NSString *)name {
    return _presets[name];
}

- (void)setPresets:(NSArray<NSDictionary *> *)presets forName:(NSString *)name {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:presets.count];
    for (NSDictionary *dict in presets) {
        [array addObject:dict.mutableCopy];
    }
    _presets[name] = array;
    
    if (_hasWindow) {
        [self updateTableViews];
    }
    _hasChanges = YES;
}

- (void)setPreset:(NSDictionary *)preset forName:(NSString *)name {
    NSMutableArray *array = _presets[name];
    if (!array) {
        array = NSMutableArray.new;
    }
    NSMutableDictionary *dict = preset.mutableCopy;
    SLHPresetNameDialog *dialog = SLHPresetNameDialog.new;
    NSString *str = dict[SLHEncoderPresetNameKey];
    if (str) {
        dialog.presetName = str;
    }
    if ([dialog runModal] == NSModalResponseOK) {
        dict[SLHEncoderPresetNameKey] = dialog.presetName;
        [array addObject:dict];
        _presets[name] = array;
        
        if (_hasWindow) {
            [self updateTableViews];
        }
        _hasChanges = YES;
    }
}

- (void)updateTableViews {
    [_groupsController setContent:self.groupsArray];
    [_presetsController setContent:self.presetsArray];
}

- (BOOL)hasChanges {
    return _hasChanges;
}

- (void)savePresets {
    NSURL *url = [NSURL fileURLWithPath:_presetsPath isDirectory:NO];
    if (![self writePresetsToURL:url]) {
        return;
    }
    _hasChanges = NO;
}

- (BOOL)writePresetsToURL:(NSURL *)url {
    NSError *error = nil;
    if (![_presets writeToURL:url error:&error]) {
        NSLog(@"%@", error);
        [self presentError:error];
        return NO;
    }
    return YES;
}

- (NSDictionary *)readPresetsFromURL:(NSURL *)url {
    NSError *error = nil;
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL:url
                                                             error:&error];
    if (!dict) {
        NSLog(@"%@", error);
        [self presentError:error];
    }
    return dict;
}

#pragma mark - Properties

- (NSArray *)groupsArray {
    return _presets.allKeys;
}

- (NSArray *)presetsArray {
    NSInteger row = _groupsTableView.selectedRow;
    if (row < 0) {
        return nil;
    }
    NSString *name = _groupsController.arrangedObjects[row];
    return _presets[name];
}

- (void)setPresetsArray:(NSArray *)presetsArray {
    NSInteger row = _groupsTableView.selectedRow;
    if (row < 0) {
        return;
    }
    NSString *name = _groupsController.arrangedObjects[row];
    _presets[name] = presetsArray;
    _hasChanges = YES;
}

#pragma mark - IBActions

- (void)showPresetsWindow:(id)sender {
    [self.window makeKeyAndOrderFront:sender];
    [self updateTableViews];
}

- (IBAction)duplicatePreset:(id)sender {
    NSInteger row = _presetsTableView.selectedRow;
    NSDictionary *dict = _presetsController.arrangedObjects[row++];
    NSMutableDictionary *dictCopy = dict.mutableCopy;
    
    SLHPresetNameDialog *dialog = SLHPresetNameDialog.new;
    dialog.presetName = dictCopy[SLHEncoderPresetNameKey];
    if ([dialog runModal] == NSModalResponseOK) {
        dictCopy[SLHEncoderPresetNameKey] = dialog.presetName;
    }
    
    [_presetsController insertObject:dictCopy atArrangedObjectIndex:row];
    [_presetsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    _hasChanges = YES;
}

- (IBAction)loadPreset:(id)sender {
    NSInteger row = _groupsTableView.selectedRow;
    if (row < 0) {
        return;
    }
    NSString *name = _groupsController.arrangedObjects[row];
    row = _presetsTableView.selectedRow;
    NSDictionary *dict = _presetsController.arrangedObjects[row];
    if (name && dict) {
        [_delegate presetManager:self loadPreset:dict forName:name];
    }
}

- (void)dispalyAlertWithText:(NSString *)messageText info:(NSString *)infoText {
    NSAlert * alert = [[NSAlert alloc] init];
    alert.messageText = messageText;
    alert.informativeText = infoText;
    [alert runModal];
}

- (IBAction)exportPresets:(id)sender {
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.allowedFileTypes = @[@"dict"];
    if ([panel runModal] == NSModalResponseOK) {
        NSURL *url = panel.URL;
        [self writePresetsToURL:url];
    }
}

- (IBAction)importPresets:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowedFileTypes = @[@"dict"];
    if ([panel runModal] == NSModalResponseOK) {
        NSURL *url = panel.URL;
        NSDictionary *dict = [self readPresetsFromURL:url];
        if (!dict) {
            return;
        }
        NSArray *allKeys = dict.allKeys;
        for (NSString *key in allKeys) {
            NSArray *new_presets = dict[key];
            NSMutableArray *old_presets = _presets[key];
            if (old_presets) {
                [old_presets addObjectsFromArray:new_presets];
            } else {
                _presets[key] = new_presets.mutableCopy;
            }
        }
        [self updateTableViews];
        _hasChanges = YES;
    }
}

#pragma mark - NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSTableView *table = notification.object;
    if (table == _groupsTableView) {
        [_presetsController setContent:self.presetsArray];
    }
}

#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification {
    _hasWindow = NO;
}

- (void)windowDidBecomeMain:(NSNotification *)notification {
    _hasWindow = YES;
}

#pragma mark - NSTextFieldDelegate 

- (void)controlTextDidEndEditing:(NSNotification *)obj {
    _hasChanges = YES;
}

@end
