//
//  SLHEncoderX264Format.m
//  Slash
//
//  Created by Terminator on 2018/12/05.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import "SLHEncoderX264Format.h"

@interface SLHEncoderX264Format () {
    
    IBOutlet NSView *_videoView;
    IBOutlet NSView *_audioView;
    
    // Video
    
    IBOutlet NSPopUpButton *_presetPopUp;
    IBOutlet NSPopUpButton *_encodingTypePopUp;
    IBOutlet NSView *_bitrateView;
    IBOutlet NSView *_crfView;
    IBOutlet NSPopUpButton *_tunePopUp;
    IBOutlet NSPopUpButton *_containerPopUp;
    
    // Audio
    
    IBOutlet NSPopUpButton *_audioCodecPopUp;
    IBOutlet NSPopUpButton *_audioSampleRatePopUp;
    IBOutlet NSPopUpButton *_audioChannelsPopUp;
    IBOutlet NSPopUpButton *_audioBitratePopUp;
    
}

@end

@implementation SLHEncoderX264Format

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

@end
