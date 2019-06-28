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
}

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
}

- (IBAction)removeArgument:(id)sender {
}

@end
