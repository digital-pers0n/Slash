//
//  SLKWindowController.m
//  Slash
//
//  Created by Terminator on 2020/08/10.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLKWindowController.h"

@interface SLKWindowController ()

@end

@implementation SLKWindowController

#pragma mark - Overrides

- (NSNibName)windowNibName {
    return self.className;
}

- (void)windowDidLoad {
    [super windowDidLoad];
}


@end
