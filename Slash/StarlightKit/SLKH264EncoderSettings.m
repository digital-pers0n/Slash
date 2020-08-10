//
//  SLKH264EncoderSettings.m
//  Slash
//
//  Created by Terminator on 2020/08/10.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLKH264EncoderSettings.h"

@interface SLKH264EncoderSettings ()

@end

@implementation SLKH264EncoderSettings

#pragma mark - Overrides

- (NSNibName)nibName {
    return self.className;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - SLKEncoderSettings Protocol

- (NSString *)displayName {
    return @"H264";
}

@end
