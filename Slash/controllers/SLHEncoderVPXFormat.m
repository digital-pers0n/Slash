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
#import "SLHEncoderVPXOptions.h"
#import "SLHMediaItem.h"
#import "SLHMediaItemTrack.h"

typedef NS_ENUM(NSUInteger, SLHVPXAudioSampleRateType) {
    SLHVPXAudioSampleRate32000 = 32000,
    SLHVPXAudioSampleRate44100 = 44100,
    SLHVPXAudioSampleRate48000 = 48000,
};

typedef NS_ENUM(NSUInteger, SLHVPXAudioChannelsType) {
    SLHVPXAudioChannels1 = 1,
    SLHVPXAudioChannels2,
    SLHVPXAudioChannels51 = 6,
};

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

- (NSString *)formatName {
    return @"VP8";
}

- (SLHEncoderItem *)encoderItem {
    return _encoderItem;
}

- (void)setEncoderItem:(SLHEncoderItem *)encoderItem {
    _encoderItem = encoderItem;
    SLHEncoderVPXOptions *videoOptions = (id)_encoderItem.videoOptions;
    SLHEncoderItemOptions *audioOptions = _encoderItem.audioOptions;
    
    if (![videoOptions isKindOfClass:[SLHEncoderVPXOptions class]]) {
        videoOptions = [[SLHEncoderVPXOptions alloc] initWithOptions:videoOptions];
        videoOptions.speed = 0;
        videoOptions.quality = SLHVPXQualityAuto;
        videoOptions.twoPass = NO;
        videoOptions.enableCRF = NO;
        videoOptions.lookAhead = 25;
        videoOptions.crf = 25;
        videoOptions.codecName = @"libvpx";
        _encoderItem.videoOptions = videoOptions;
        _encoderItem.container = @"webm";
        NSString *outputFileName = _encoderItem.outputFileName;
        outputFileName = [outputFileName stringByDeletingPathExtension];
        outputFileName = [outputFileName stringByAppendingPathExtension:@"webm"];
        _encoderItem.outputFileName = outputFileName;
        
        audioOptions.codecName = @"libopus";
        audioOptions.bitRate = 128;
        audioOptions.sampleRate = SLHVPXAudioSampleRate44100;
        audioOptions.numberOfChannels = SLHVPXAudioChannels2;
    }
    
    if (self.view) {
        [_qualityPopUp selectItemWithTag:videoOptions.quality];
        [_sampleRatePopUp selectItemWithTag:audioOptions.sampleRate];
        [_channelsPopUp selectItemWithTag:audioOptions.numberOfChannels];
        
        _filters.encoderItem = _encoderItem;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _filters = [SLHFiltersController filtersController];
}

#pragma mark - IBActions

- (IBAction)qualityDidChange:(NSPopUpButton *)sender {
    ((SLHEncoderVPXOptions *)_encoderItem.videoOptions).quality = sender.selectedTag;
}
- (IBAction)sampleRateDidChange:(NSPopUpButton *)sender {
    _encoderItem.audioOptions.sampleRate = sender.selectedTag;
}
- (IBAction)channelsDidChange:(NSPopUpButton *)sender {
    _encoderItem.audioOptions.numberOfChannels = sender.selectedTag;
}

- (IBAction)widthDidChange:(id)sender {
    NSInteger videoIdx = _encoderItem.videoStreamIndex;
    if (_keepAspectRatio && videoIdx > -1) {
        NSSize size = _encoderItem.mediaItem.tracks[videoIdx].videoSize;
        double aspect = size.width / size.height;
        SLHEncoderItemOptions *options = _encoderItem.videoOptions;
        options.videoHeight = options.videoWidth / aspect;
    }
}

- (IBAction)heightDidChange:(id)sender {
    NSInteger videoIdx = _encoderItem.videoStreamIndex;
    if (_keepAspectRatio && videoIdx > -1) {
        NSSize size = _encoderItem.mediaItem.tracks[videoIdx].videoSize;
        double aspect = size.width / size.height;
        SLHEncoderItemOptions *options = _encoderItem.videoOptions;
        options.videoWidth = options.videoHeight * aspect;
    }
}


#pragma mark - Private 

- (void)_initializePopUps {
    NSMenuItem *menuItem;
    NSMenu *menu;
    
    // Video
    
    {   // qualityPopUp
        menu = _qualityPopUp.menu;
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"Best" action:nil keyEquivalent:@""];
        menuItem.tag = SLHVPXQualityBest;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"Good" action:nil keyEquivalent:@""];
        menuItem.tag = SLHVPXQualityGood;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"Realtime" action:nil keyEquivalent:@""];
        menuItem.tag = SLHVPXQualityRealtime;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"Auto" action:nil keyEquivalent:@""];
        menuItem.tag = SLHVPXQualityAuto;
        [menu addItem:menuItem];
    }
    
    // Audio
    
    {   // sampleRatePopUp
        menu = _sampleRatePopUp.menu;
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"32000 Hz" action:nil keyEquivalent:@""];
        menuItem.tag = SLHVPXAudioSampleRate32000;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"441000 Hz" action:nil keyEquivalent:@""];
        menuItem.tag = SLHVPXAudioSampleRate44100;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"48000 Hz" action:nil keyEquivalent:@""];
        menuItem.tag = SLHVPXAudioSampleRate48000;
        [menu addItem:menuItem];
        
    }
    
    {   // channelsPopUp
        menu = _channelsPopUp.menu;
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"Mono" action:nil keyEquivalent:@""];
        menuItem.tag = SLHVPXAudioChannels1;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"Stereo" action:nil keyEquivalent:@""];
        menuItem.tag = SLHVPXAudioChannels2;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"5.1" action:nil keyEquivalent:@""];
        menuItem.tag = SLHVPXAudioChannels51;
        [menu addItem:menuItem];
        
    }

}

@end
