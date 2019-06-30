//
//  SLHEncoderUniversalFormat.m
//  Slash
//
//  Created by Terminator on 2019/06/28.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHEncoderUniversalFormat.h"

@interface SLHEncoderUniversalFormat () <NSTableViewDataSource> {

    IBOutlet NSTableView *_tableView;
    NSMutableArray *_dataSource;
    SLHFiltersController *_filters;
    SLHEncoderItem *_encoderItem;
}

@property SLHEncoderUniversalOptions *videoArguments;
@property SLHEncoderUniversalOptions *audioArguments;

@end

@implementation SLHEncoderUniversalFormat

- (NSString *)nibName {
    return self.className;
}

- (NSString *)formatName {
    return @"Universal";
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

#pragma mark - IBActions

- (IBAction)addArgument:(id)sender {
    NSInteger idx = _tableView.selectedRow + 1;
    [_dataSource insertObject:@"(Empty)" atIndex:idx];
    [_tableView reloadData];
    [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
    [_tableView scrollRowToVisible:idx];
}

- (IBAction)removeArgument:(id)sender {
    NSInteger idx = _tableView.selectedRow;
    if (idx > -1) {
        [_dataSource removeObjectAtIndex:idx--];
        [_tableView reloadData];
        [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
        [_tableView scrollRowToVisible:idx];
    } else {
        NSBeep();
    }
}

#pragma mark - NSTableView DataSource

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row < _dataSource.count) {
        return _dataSource[row];
    }
    return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row < _dataSource.count && object) {
        _dataSource[row] = object;
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _dataSource.count;
}

#pragma mark - SLHEncoderSettingsDelegate

- (NSView *)encoderSettings:(SLHEncoderSettings *)enc viewForTab:(SLHEncoderSettingsTab) tab {
    switch (tab) {
        case SLHEncoderSettingsVideoTab:
            _dataSource = _videoArguments.arguments;
            break;
        case SLHEncoderSettingsAudioTab:
            _dataSource = _audioArguments.arguments;
            break;
        case SLHEncoderSettingsFiltersTab:
            return _filters.view;
            break;
            
        default:
            break;
    }
    [_tableView reloadData];
    return self.view;
}



@end
