//
//  SLHEncoderX264Format.m
//  Slash
//
//  Created by Terminator on 2018/12/05.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import "SLHEncoderX264Format.h"
#import "SLHEncoderX264Options.h"
#import "SLHEncoderItem.h"
#import "SLHFiltersController.h"


@interface SLHEncoderX264Format () {
    
    SLHFiltersController *_filters;
    SLHEncoderItem *_encoderItem;
    
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

- (NSString *)nibName {
    return self.className;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _filters = [SLHFiltersController filtersController];
    
    // Do view setup here.
}

- (NSString *)formatName {
    return @"H264";
}

- (SLHEncoderItem *)encoderItem {
    return _encoderItem;
}

- (void)setEncoderItem:(SLHEncoderItem *)encoderItem {
    _encoderItem = encoderItem;
    if (![_encoderItem.videoOptions isKindOfClass:[SLHEncoderX264Options class]]) {
        _encoderItem.videoOptions = [[SLHEncoderX264Options alloc] initWithOptions:_encoderItem.videoOptions];
    }
}

#pragma mark - SLHEncoderSettingsDelegate

- (NSView *)encoderSettings:(SLHEncoderSettings *)enc viewForTab:(SLHEncoderSettingsTab) tab {
    NSView *view = nil;
    switch (tab) {
        case SLHEncoderSettingsVideoTab:
            view = _videoView;
            break;
        case SLHEncoderSettingsAudioTab:
            view = _audioView;
            break;
        case SLHEncoderSettingsFiltersTab:
            view = _filters.view;
            _filters.encoderItem = self.encoderItem;
            break;
            
        default:
            break;
    }
    return view;
}

@end
