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

- (NSString *)nibName {
    return self.className;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

@end
