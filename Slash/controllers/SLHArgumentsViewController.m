//
//  SLHArgumentsViewController.m
//  Slash
//
//  Created by Terminator on 2019/05/14.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHArgumentsViewController.h"
#import "SLHEncoderItem.h"

@interface SLHArgumentsViewController () <NSTableViewDataSource> {
    IBOutlet NSTableView *_tableView;
    NSMutableArray <NSString *> *_dataSource;
    NSMutableArray <NSMutableArray <NSString *> *> *_arguments;
    SLHEncoderItem *_encoderItem;
    IBOutlet NSPopUpButton *_passPopUp;
}

@end

@implementation SLHArgumentsViewController

#pragma mark - Initialization

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self _setUp];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self _setUp];
    }
    return self;
}

- (void)_setUp {
    _dataSource = [NSMutableArray new];
    _arguments = [NSMutableArray new];
}

- (NSString *)nibName {
    return self.className;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

#pragma mark - Methods

- (void)setEncoderItem:(SLHEncoderItem *)encoderItem {
    NSMenu *menu = _passPopUp.menu;
    [menu removeAllItems];
    [_arguments removeAllObjects];
    int index = 1;
    for (NSArray *a in encoderItem.encoderArguments) {
        [_arguments addObject:a.mutableCopy];
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Pass %i", index++] action:nil keyEquivalent:@""];
        [menu addItem:item];
    }
    [_passPopUp selectItemAtIndex:0];
    _dataSource = _arguments[0];
    [_tableView reloadData];
}

- (SLHEncoderItem *)encoderItem {
    return _encoderItem;
}

#pragma mark - IBActions

- (IBAction)applyChanges:(id)sender {
    _encoderItem.encoderArguments = _arguments.copy;
}

- (IBAction)passDidChange:(id)sender {
    NSInteger index = _passPopUp.indexOfSelectedItem;
    _dataSource = _arguments[index];
    [_tableView reloadData];
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

@end
