//
//  SLKContainerView.m
//  Slash
//
//  Created by Terminator on 2020/10/13.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLKContainerView.h"

@implementation SLKContainerView

- (void)viewWillStartLiveResize {
    [super viewWillStartLiveResize];
    [_delegate viewWillStartLiveResize:self];
}

- (void)viewDidEndLiveResize {
    [super viewDidEndLiveResize];
    [_delegate viewDidEndLiveResize:self];
}

@end
