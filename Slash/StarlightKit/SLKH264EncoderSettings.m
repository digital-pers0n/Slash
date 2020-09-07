//
//  SLKH264EncoderSettings.m
//  Slash
//
//  Created by Terminator on 2020/08/10.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLKH264EncoderSettings.h"
#import "SLKStackView.h"
#import "SLKDisclosureView.h"
#import "SLTH264EncoderSettings.h"

@interface SLKH264EncoderSettings () {
    __unsafe_unretained IBOutlet SLKStackView *_stackView;
    __unsafe_unretained IBOutlet NSView *_videoSettings;
    __unsafe_unretained IBOutlet NSView *_audioSettings;
}

@property (nonatomic) SLTH264EncoderSettings *settings;

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
