//
//  SLKPlayerViewController.m
//  Slash
//
//  Created by Terminator on 2020/10/11.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLKPlayerViewController.h"
#import "MPVPlayer.h"
#import "MPVOpenGLView.h"
#import "MPVIOSurfaceView.h"

@interface SLKPlayerViewController ()

@end

@implementation SLKPlayerViewController

+ (NSArray<NSString *> *)allowedPlayerViewNames {
    static id allowedNames = nil;
    if (!allowedNames) {
        allowedNames = @[ NSStringFromClass(MPVOpenGLView.class),
                          NSStringFromClass(MPVIOSurfaceView.class) ];
    }
    return allowedNames;
}

- (NSNibName)nibName {
    return self.className;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

@end
