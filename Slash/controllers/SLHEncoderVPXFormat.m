//
//  SLHEncoderVPXFormat.m
//  Slash
//
//  Created by Terminator on 2019/05/27.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHEncoderVPXFormat.h"
#import "SLHEncoderItem.h"
#import "SLHFiltersController.h"

@interface SLHEncoderVPXFormat () {
    SLHFiltersController *_filters;
    SLHEncoderItem *_encoderItem;
    
    IBOutlet NSView *_videoView;
    IBOutlet NSView *_audioView;
    IBOutlet NSPopUpButton *_qualityPopUp;
    IBOutlet NSPopUpButton *_sampleRatePopUp;
    IBOutlet NSPopUpButton *_channelsPopUp;
    
}

@property BOOL keepAspectRatio;

@end

@implementation SLHEncoderVPXFormat

- (NSString *)nibName {
    return self.className;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

#pragma mark - IBActions

- (IBAction)qualityDidChange:(NSPopUpButton *)sender {
}
- (IBAction)sampleRateDidChange:(NSPopUpButton *)sender {
}
- (IBAction)channelsDidChange:(NSPopUpButton *)sender {
}
- (IBAction)widthDidChange:(id)sender {
}
- (IBAction)heightDidChange:(id)sender {
}

@end
