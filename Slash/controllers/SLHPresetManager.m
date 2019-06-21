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


@interface SLHPresetManager () {
    NSMutableDictionary *_presets;
    NSString *_presetsPath;
    
    IBOutlet NSArrayController *_groupsController;
    IBOutlet NSArrayController *_presetsController;
    IBOutlet NSTableView *_groupsTableView;
    IBOutlet NSTableView *_presetsTableView;
}

@property NSMutableDictionary *presets;
@property (readonly) NSArray *groupsArray;
@property NSArray *presetsArray;

@end

@implementation SLHPresetManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSString *presetsPath = [SLHPreferences.preferences.appSupportPath stringByAppendingPathComponent:@"presets.dict"];
        NSMutableDictionary *presets = [NSMutableDictionary dictionaryWithContentsOfFile:presetsPath];
        if (!presets) {
            presets = NSMutableDictionary.new;
        }
        _presets = presets;
        _presetsPath = presetsPath;
        
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
    }
}

- (void)savePresets {
    [_presets writeToFile:_presetsPath atomically:YES];
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
}

#pragma mark - IBActions

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

@end
