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
#import "SLHMediaItem.h"
#import "SLHFiltersController.h"

typedef NS_ENUM(NSUInteger, SLHX264AudioSampleRateType) {
    SLHX264AudioSampleRate32000,
    SLHX264AudioSampleRate44100,
    SLHX264AudioSampleRate48000,
};

typedef NS_ENUM(NSUInteger, SLHX264AudioChannelsType) {
    SLHX264AudioChannels1 = 1,
    SLHX264AudioChannels2,
    SLHX264AudioChannels51 = 6,
};

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
    IBOutlet NSPopUpButton *_profilePopUp;
    IBOutlet NSPopUpButton *_levelPopUp;
    
    IBOutlet NSSlider *_maxBitrateSlider;
    
    
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
    [self _initializePopUps];
    
    // Set up _crfView

    _crfView.hidden = YES;
    _crfView.frame = _bitrateView.frame;
    _crfView.autoresizingMask = _bitrateView.autoresizingMask;
    [_videoView addSubview:_crfView];

}

- (NSString *)formatName {
    return @"H264";
}

- (SLHEncoderItem *)encoderItem {
    return _encoderItem;
}

- (void)setEncoderItem:(SLHEncoderItem *)encoderItem {
    _encoderItem = encoderItem;
    SLHEncoderX264Options *options = (SLHEncoderX264Options *)_encoderItem.videoOptions;
    
    if (![_encoderItem.videoOptions isKindOfClass:[SLHEncoderX264Options class]]) {
        options = [[SLHEncoderX264Options alloc] initWithOptions:options];
        options.encodingType = SLHX264EncodingSinglePass;
        options.presetType = SLHX264PresetNone;
        options.profileType = SLHX264ProfileNone;
        options.levelType = SLHX264LevelNone;
        options.tuneType = SLHX264TuneNone;
        options.containerType = SLHX264ContainerMP4;
        options.codecName = @"libx264";
        _encoderItem.videoOptions = options;
    }
    
    if (self.view) {
        [_presetPopUp selectItemWithTag:options.presetType];
        [_encodingTypePopUp selectItemWithTag:options.encodingType];
        [_tunePopUp selectItemWithTag:options.tuneType];
        [_containerPopUp selectItemWithTag:options.containerType];
        [_profilePopUp selectItemWithTag:options.profileType];
        [_levelPopUp selectItemWithTag:options.levelType];
        [self _changeEncodingType];
    }
}

#pragma mark - IBActions

- (IBAction)presetDidChange:(NSPopUpButton *)sender {
    ((SLHEncoderX264Options *)_encoderItem.videoOptions).presetType = sender.selectedTag;
}

- (IBAction)encodingTypeDidChange:(NSPopUpButton *)sender {
    ((SLHEncoderX264Options *)_encoderItem.videoOptions).encodingType = sender.selectedTag;
    [self _changeEncodingType];
}

- (IBAction)tuneDidChange:(NSPopUpButton *)sender {
    ((SLHEncoderX264Options *)_encoderItem.videoOptions).tuneType = sender.selectedTag;
}

- (IBAction)containerDidChange:(NSPopUpButton *)sender {
    ((SLHEncoderX264Options *)_encoderItem.videoOptions).containerType = sender.selectedTag;
}

- (IBAction)profileDidChange:(NSPopUpButton *)sender {
    ((SLHEncoderX264Options *)_encoderItem.videoOptions).profileType = sender.selectedTag;
}

- (IBAction)levelDidChange:(NSPopUpButton *)sender {
    ((SLHEncoderX264Options *)_encoderItem.videoOptions).levelType = sender.selectedTag;
}

#pragma mark - Private

- (void)_changeEncodingType {
    SLHEncoderX264Options *options = (SLHEncoderX264Options *)_encoderItem.videoOptions;
    switch (options.encodingType) {
        case SLHX264EncodingSinglePass:
            _crfView.hidden = YES;
            _bitrateView.hidden = NO;
            _maxBitrateSlider.hidden = YES;
            
            break;
            
        case SLHX264EncodingTwoPass:
            _crfView.hidden = YES;
            _bitrateView.hidden = NO;
            _maxBitrateSlider.hidden = NO;

            break;
            
        case SLHX264EncodingCRFSinglePass:
            _crfView.hidden = NO;
            _bitrateView.hidden = YES;
            
        default:
            break;
    }
}

- (void)_initializePopUps {
    NSMenuItem *menuItem;
    NSMenu *menu;
    
    // Video
    
    {   // encodingTypePopUp
        menu = _encodingTypePopUp.menu;
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"Single Pass" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264EncodingSinglePass;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"Two Pass" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264EncodingTwoPass;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"CRF" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264EncodingCRFSinglePass;
        [menu addItem:menuItem];
    }
    
    {   // presetPopUp
        menu = _presetPopUp.menu;
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"Ultra Fast" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264PresetUltrafast;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"Super Fast" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264PresetSuperfast;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"Very Fast" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264PresetVeryfast;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"Faster" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264PresetFaster;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"Fast" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264PresetFast;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"Medium" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264PresetMedium;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"Slow" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264PresetSlow;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"Slower" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264PresetSlower;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"Very Slow" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264PresetVeryslow;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"Placebo" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264PresetPlacebo;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"None" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264PresetNone;
        [menu addItem:menuItem];
    }
    
    {   // tunePopUp
        menu = _tunePopUp.menu;
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"Film" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264TuneFilm;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"Animation" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264TuneAnimation;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"Preserve Grain" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264TuneGrain;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"Still Image" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264TuneStill;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"PSNR" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264TunePsnr;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"SSIM" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264TuneSsim;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"None" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264TuneNone;
        [menu addItem:menuItem];
    }
    
    {   // containerPopUp
        menu = _containerPopUp.menu;
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"MP4" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264ContainerMP4;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"M4V" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264ContainerM4V;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"MKV" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264ContainerMKV;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"MOV" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264ContainerMOV;
        [menu addItem:menuItem];
    }
    
    {   // profilePopUp
        menu = _profilePopUp.menu;
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"Baseline" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264ProfileBaseline;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"Main" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264ProfileMain;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"High" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264ProfileHigh;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"Auto" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264ProfileNone;
        [menu addItem:menuItem];
    }
    
    {   // levelPopUp
        menu = _levelPopUp.menu;
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"1.0" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264Level10;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"1.1" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264Level11;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"1.2" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264Level12;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"1.3" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264Level13;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"2.0" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264Level20;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"2.1" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264Level21;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"2.2" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264Level22;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"3.0" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264Level30;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"3.1" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264Level31;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"3.2" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264Level32;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"4.0" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264Level40;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"4.1" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264Level41;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"4.2" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264Level42;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"5.0" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264Level50;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"5.1" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264Level51;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"Auto" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264LevelNone;
        [menu addItem:menuItem];
    }
    
    // Audio
    
    {   // audioCodecPopUp
        // there is only one codec
        menu = _audioCodecPopUp.menu;
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"AAC" action:nil keyEquivalent:@""];
        [menu addItem:menuItem];
    }
    
    {   // audioSampleRatePopUp
        menu = _audioSampleRatePopUp.menu;
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"32000 Hz" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264AudioSampleRate32000;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"441000 Hz" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264AudioSampleRate44100;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"48000 Hz" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264AudioSampleRate48000;
        [menu addItem:menuItem];

    }
    
    {   // audioChannelsPopUp
        menu = _audioChannelsPopUp.menu;
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"Mono" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264AudioChannels1;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"Stereo" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264AudioChannels2;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"5.1" action:nil keyEquivalent:@""];
        menuItem.tag = SLHX264AudioChannels51;
        [menu addItem:menuItem];
        
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
