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
#import "SLHFilterOptions.h"
#import "SLHMediaItem.h"
#import "SLHMediaItemTrack.h"
#import "SLHPreferences.h"
#import "SLHEncoderItemMetadata.h"

extern NSString *const SLHEncoderMediaMapKey,
                *const SLHEncoderMediaContainerKey,
                *const SLHEncoderMediaStartTimeKey,
                *const SLHEncoderMediaEndTimeKey,
                *const SLHEncoderMediaNoSubtitlesKey,
                *const SLHEncoderMediaNoAudioKey,
                *const SLHEncoderMediaNoVideoKey,
                *const SLHEncoderMediaOverwriteFilesKey,
                *const SLHEncoderMediaThreadsKey,
                *const SLHEncoderMediaPassKey,
                *const SLHEncoderMediaPassLogKey,
                *const SLHEncoderAudioCodecKey,
                *const SLHEncoderAudioBitrateKey,
                *const SLHEncoderAudioSampleRateKey,
                *const SLHEncoderAudioChannelsKey,
                *const SLHEncoderVideoCodecKey,
                *const SLHEncoderVideoBitrateKey,
                *const SLHEncoderVideoMaxBitrateKey,
                *const SLHEncoderVideoBufsizeKey,
                *const SLHEncoderVideoCRFBitrateKey,
                *const SLHEncoderVideoAspectRatioKey,
                *const SLHEncoderVideoPixelFormatKey,
                *const SLHEncoderVideoScaleSizeKey,
                *const SLHEncoderVideoMaxGopSizeKey,
                *const SLHEncoderVideoVPXSpeedKey,
                *const SLHEncoderVideoVPXLagInFramesKey,
                *const SLHEncoderVideoVPXQualityKey,
                *const SLHEncoderVideoVPXAutoAltRefKey;

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
    IBOutlet NSPopUpButton *_channelsPopUp;
    
}

@property SLHEncoderVPXOptions *options;
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
        videoOptions.lagInFrames = 25;
        videoOptions.enableAltRef = YES;
        videoOptions.crf = 25;
        videoOptions.maxGopSize = 128;
        videoOptions.codecName = @"libvpx";
        _encoderItem.videoOptions = videoOptions;
        _encoderItem.container = @"webm";
        NSString *outputFileName = _encoderItem.outputFileName;
        outputFileName = [outputFileName stringByDeletingPathExtension];
        outputFileName = [outputFileName stringByAppendingPathExtension:@"webm"];
        _encoderItem.outputFileName = outputFileName;
        
        audioOptions.codecName = @"libopus";
        audioOptions.bitRate = 128;
        audioOptions.numberOfChannels = SLHVPXAudioChannels2;
    }
    
    self.options = videoOptions;
    if (self.view) {
        [_qualityPopUp selectItemWithTag:videoOptions.quality];
        [_channelsPopUp selectItemWithTag:audioOptions.numberOfChannels];
        
        _filters.encoderItem = _encoderItem;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self _initializePopUps];
    _filters = [SLHFiltersController filtersController];
}

- (NSArray *)arguments {
    NSString *ffmpegPath = SLHPreferences.preferences.ffmpegPath;
    if (!ffmpegPath) {
        NSLog(@"%s: ffmpeg file path is not set", __PRETTY_FUNCTION__);
        return nil;
    }
    
    SLHEncoderVPXOptions *options = (id)_encoderItem.videoOptions;
    TimeInterval ti = _encoderItem.interval;
    NSMutableArray *args = @[  ffmpegPath, @"-nostdin", @"-hide_banner",
                               SLHEncoderMediaOverwriteFilesKey,
                               @"-ss", @(ti.start).stringValue,
                               @"-i", _encoderItem.mediaItem.filePath,
                               SLHEncoderMediaNoSubtitlesKey,
                               SLHEncoderMediaEndTimeKey,
                               @(ti.end - ti.start).stringValue,
                               SLHEncoderMediaThreadsKey,
                               @(SLHPreferences.preferences.numberOfThreads).stringValue,
                               ].mutableCopy;
    
    NSMutableArray *videoArgs = NSMutableArray.new;
    if (_encoderItem.videoStreamIndex >= 0) {
        [videoArgs addObject:SLHEncoderMediaMapKey];
        [videoArgs addObject:[NSString stringWithFormat:@"0:%li", _encoderItem.videoStreamIndex]];
        [videoArgs addObjectsFromArray:[self videoArguments]];
    } else {
        [videoArgs addObject:SLHEncoderMediaNoVideoKey ];
    }
    

    NSMutableArray *audioArgs = NSMutableArray.new;
    if (_encoderItem.audioStreamIndex >= 0) {
        [audioArgs addObject:SLHEncoderMediaMapKey];
        [audioArgs addObject:[NSString stringWithFormat:@"0:%li", _encoderItem.audioStreamIndex]];
        [audioArgs addObjectsFromArray:[self audioArguments]];
    } else {
        [audioArgs addObject:SLHEncoderMediaNoAudioKey ];
    }
    
    NSArray *filterArgs = _filters.arguments;
    NSMutableArray *output = NSMutableArray.new;
    if (options.twoPass) {
        extern char *g_temp_dir;
        [args addObject:SLHEncoderMediaPassLogKey];
        [args addObject:@(g_temp_dir)];
        [args addObject:SLHEncoderMediaPassKey];
        NSMutableArray *passOne = args.mutableCopy;
        [passOne addObject:@"1"];
        [passOne addObjectsFromArray:[self firstPassArguments]];
        [passOne addObject:SLHEncoderMediaContainerKey];
        [passOne addObject:@"null"];
        [passOne addObject:@"/dev/null"];
        [args addObject:@"2"];
        [output addObject:passOne];
    }
    
    [args addObjectsFromArray:videoArgs];
    [args addObjectsFromArray:audioArgs];
    [args addObjectsFromArray:filterArgs];
    [args addObjectsFromArray:_encoderItem.metadata.arguments];
    [args addObject:_encoderItem.outputPath];
    [output addObject:args];
    return output;
}

#pragma mark - IBActions

- (IBAction)qualityDidChange:(NSPopUpButton *)sender {
    ((SLHEncoderVPXOptions *)_encoderItem.videoOptions).quality = sender.selectedTag;
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

- (NSArray *)audioArguments {
    SLHEncoderItemOptions *audioOpts = _encoderItem.audioOptions;
    NSArray *args = @[
                      SLHEncoderAudioCodecKey, audioOpts.codecName,
                      SLHEncoderAudioBitrateKey, @(audioOpts.bitRate * 1000).stringValue,
                      SLHEncoderAudioChannelsKey, @(audioOpts.numberOfChannels).stringValue
                      ];
    return args;
}

- (NSArray *)firstPassArguments {
    SLHEncoderVPXOptions *options = (id)_encoderItem.videoOptions;
    NSMutableArray *args = [NSMutableArray new];


    
    [args addObject:SLHEncoderVideoCodecKey];
    [args addObject:options.codecName];
    
    NSUInteger bitrate = options.bitRate * 1000;
    if (options.enableCRF) {
        [args addObject:SLHEncoderVideoCRFBitrateKey];
        [args addObject:@(options.crf).stringValue];
        [args addObject:SLHEncoderVideoBitrateKey];
        [args addObject:@(bitrate).stringValue];
    } else {
        [args addObject:SLHEncoderVideoBitrateKey];
        [args addObject:@(bitrate).stringValue];
        [args addObject:SLHEncoderVideoMaxBitrateKey];
        [args addObject:@(bitrate).stringValue];
        [args addObject:SLHEncoderVideoBufsizeKey];
        [args addObject:@(bitrate * 2).stringValue];
    }
    
    [args addObject:SLHEncoderVideoMaxGopSizeKey];
    [args addObject:@(options.maxGopSize).stringValue];
   
    [args addObject:SLHEncoderVideoVPXSpeedKey];
    [args addObject:@"4"];
    
    [args addObject:SLHEncoderVideoVPXAutoAltRefKey];
    [args addObject:@(options.enableAltRef).stringValue];
    [args addObject:SLHEncoderVideoVPXLagInFramesKey];
    [args addObject:@(options.lagInFrames).stringValue];
    
    if (options.scale) {
        
        NSUInteger width = options.videoWidth;
        NSUInteger height = options.videoHeight;
        NSString *value = [NSString stringWithFormat:@"%lux%lu", width, height];
        [args addObject:SLHEncoderVideoScaleSizeKey];
        [args addObject:value];
        [args addObject:SLHEncoderVideoAspectRatioKey];
        [args addObject:@((float)width / height).stringValue];
    }
    
    
    [args addObject:SLHEncoderVideoPixelFormatKey];
    [args addObject:@"yuv420p"];
    [args addObject:SLHEncoderMediaNoAudioKey];
    [args addObjectsFromArray:_filters.arguments];
    return args;
}

- (NSArray *)videoArguments {
    SLHEncoderVPXOptions *options = (id)_encoderItem.videoOptions;
    NSMutableArray *args = [NSMutableArray new];
    
    [args addObject:SLHEncoderVideoCodecKey];
    [args addObject:options.codecName];
    
    
    NSUInteger bitrate = options.bitRate * 1000;
    if (options.enableCRF) {
        [args addObject:SLHEncoderVideoCRFBitrateKey];
        [args addObject:@(options.crf).stringValue];
        [args addObject:SLHEncoderVideoBitrateKey];
        [args addObject:@(bitrate).stringValue];
    } else {
        [args addObject:SLHEncoderVideoBitrateKey];
        [args addObject:@(bitrate).stringValue];
        if (options.twoPass) {
            [args addObject:SLHEncoderVideoMaxBitrateKey];
            [args addObject:@(bitrate).stringValue];
            [args addObject:SLHEncoderVideoBufsizeKey];
            [args addObject:@(bitrate * 2).stringValue];
        }
    }
    
    [args addObject:SLHEncoderVideoMaxGopSizeKey];
    [args addObject:@(options.maxGopSize).stringValue];
    
    [args addObject:SLHEncoderVideoVPXSpeedKey];
    [args addObject:@(options.speed).stringValue];
    
    [args addObject:SLHEncoderVideoVPXAutoAltRefKey];
    [args addObject:@(options.enableAltRef).stringValue];
    [args addObject:SLHEncoderVideoVPXLagInFramesKey];
    [args addObject:@(options.lagInFrames).stringValue];
    
    SLHVPXQualityType quality = options.quality;
    if (quality != SLHVPXQualityAuto) {
        
        [args addObject:SLHEncoderVideoVPXQualityKey];
        switch (options.quality) {
            case SLHVPXQualityBest:
                [args addObject:@"best"];
                break;
            case SLHVPXQualityGood:
                [args addObject:@"good"];
                break;
            case SLHVPXQualityRealtime:
            default:
                [args addObject:@"realtime"];
                break;
        }
    }
    
    if (options.scale) {
        NSUInteger width = options.videoWidth;
        NSUInteger height = options.videoHeight;
        NSString *value = [NSString stringWithFormat:@"%lux%lu", width, height];
        [args addObject:SLHEncoderVideoScaleSizeKey];
        [args addObject:value];
        [args addObject:SLHEncoderVideoAspectRatioKey];
        [args addObject:@((float)width / height).stringValue];
    }

    [args addObject:SLHEncoderVideoPixelFormatKey];
    [args addObject:@"yuv420p"];
    
    return args;
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
            break;
            
        default:
            break;
    }
    return view;
}

@end
