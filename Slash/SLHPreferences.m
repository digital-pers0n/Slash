//
//  SLHPreferences.m
//  Slash
//
//  Created by Terminator on 9/28/18.
//  Copyright © 2018 digital-pers0n. All rights reserved.
//

#import "SLHPreferences.h"

extern NSString *const SLHPreferencesDefaultOutputPath;

@interface SLHPreferences () {
    
    IBOutlet NSPopUpButton *_outputPathPopUp;
    
    NSMutableArray <NSString *> *_recentOutputPaths;
    NSString *_currentOutputPath;

}

@property IBOutlet NSTextField *ffmpegPathTextField;
@property IBOutlet NSTextField *ffprobePathTextField;
@property IBOutlet NSTextField *mpvPathTextField;

@end

@implementation SLHPreferences

- (NSString *)windowNibName {
    return self.className;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _recentOutputPaths = [[NSUserDefaults standardUserDefaults]
                              arrayForKey:SLHPreferencesRecentOutputPaths].mutableCopy;
        if (!_recentOutputPaths) {
            _recentOutputPaths = [[NSMutableArray alloc] init];
        }
        
        if (_recentOutputPaths.count) {
            _currentOutputPath = _recentOutputPaths[0];
        } else {
            _currentOutputPath = [SLHPreferencesDefaultOutputPath stringByExpandingTildeInPath];
        }

    }
    return self;
}

- (void)windowDidClose:(NSNotification *)notification {
    [[NSUserDefaults standardUserDefaults] setObject:_recentOutputPaths forKey:SLHPreferencesRecentOutputPaths];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidClose:) name:NSWindowWillCloseNotification object:self.window];
}

- (BOOL)outputPathSameAsInput {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"outputPathSameAsInput"];
}

- (void)setOutputPathSameAsInput:(BOOL)value {
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:@"outputPathSameAsInput"];
}

#pragma mark - IBActions

- (IBAction)selectFile:(NSButton *)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSFileHandlingPanelOKButton) {
            NSString *value = panel.URLs.firstObject.path;
            [[NSUserDefaults standardUserDefaults] setValue:value forKey:sender.identifier];
            switch (sender.tag) {
                case 1:
                    _ffmpegPathTextField.stringValue = value;
                    break;
                case 2:
                    _ffprobePathTextField.stringValue = value;
                    break;
                case 3:
                    _mpvPathTextField.stringValue = value;
                    break;
                    
                default:
                    break;
            }
        }
    }];
    
}

- (IBAction)selectOutputPath:(NSMenuItem *)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = NO;
    panel.canChooseFiles = NO;
    panel.canChooseDirectories = YES;
    panel.canCreateDirectories = YES;
    
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSFileHandlingPanelOKButton) {
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
    }];
    
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

@end
