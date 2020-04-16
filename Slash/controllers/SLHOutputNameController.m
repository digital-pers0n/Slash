//
//  SLHOutputNameController.m
//  Slash
//
//  Created by Terminator on 2020/04/14.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLHOutputNameController.h"

@interface SLHOutputNameController ()

@end

@implementation SLHOutputNameController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (IBAction)selectNext:(id)sender {
    [_encoderItemsArrayController selectNext:nil];
}

- (IBAction)selectPrevious:(id)sender {
    [_encoderItemsArrayController selectPrevious:nil];
}

@end
