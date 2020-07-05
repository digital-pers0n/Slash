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
#import "SLHPreferences.h"
#import "SLHEncoderItemMetadata.h"

#import "MPVPlayerItem.h"
#import "MPVPlayerItemTrack.h"

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
                *const SLHEncoderAudioQualityKey,
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
                *const SLHEncoderVideoVPXAutoAltRefKey,
                *const SLHEncoderVideoVPXEnableTwoPassKey,
                *const SLHEncoderVideoVPXEnableCRFKey,
                *const SLHEncoderVideoVPXUseVorbisAudioKey;

typedef NS_ENUM(NSUInteger, SLHVPXAudioChannelsType) {
    SLHVPXAudioChannels1 = 1,
    SLHVPXAudioChannels2,
    SLHVPXAudioChannels51 = 6,
};

typedef NS_ENUM(NSUInteger, SLHVPXAudioCodecType) {
    SLHVPXAudioCodecOpus = 0,
    SLHVPXAudioCodecVorbis = 1
};

@interface SLHEncoderVPXFormat () {
    SLHFiltersController *_filters;
    SLHEncoderItem *_encoderItem;
    
    IBOutlet NSView *_videoView;
    IBOutlet NSView *_audioView;
    IBOutlet NSPopUpButton *_qualityPopUp;
    IBOutlet NSPopUpButton *_channelsPopUp;
    IBOutlet NSPopUpButton *_audioCodecPopUp;
}

@property SLHEncoderVPXOptions *options;
@property BOOL keepAspectRatio;

@end

@implementation SLHEncoderVPXFormat

- (instancetype)init
{
    self = [super init];
    if (self) {
        _cpuUsedMaxValue = 16;
        _cpuUsedMinValue = -16;
    }
    return self;
}

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
    super.encoderItem = encoderItem;
    _encoderItem = encoderItem;
    SLHEncoderVPXOptions *videoOptions = (id)_encoderItem.videoOptions;
    SLHEncoderItemOptions *audioOptions = _encoderItem.audioOptions;
    
    if (![videoOptions isKindOfClass:[SLHEncoderVPXOptions class]]) {
        videoOptions = [[SLHEncoderVPXOptions alloc] initWithOptions:videoOptions];
        videoOptions.speed = 0;
        videoOptions.vpxQuality = SLHVPXQualityAuto;
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
        NSUInteger aBitRate = audioOptions.bitRate;
        audioOptions.bitRate = (aBitRate) ? aBitRate : 128;
        audioOptions.numberOfChannels = SLHVPXAudioChannels2;
        audioOptions.quality = 3;
    }
    
    self.options = videoOptions;
    if (self.view) {
        [_qualityPopUp selectItemWithTag:videoOptions.vpxQuality];
        [_channelsPopUp selectItemWithTag:audioOptions.numberOfChannels];
        [_audioCodecPopUp selectItemWithTag:(_options.useVorbisAudio) ? SLHVPXAudioCodecVorbis : SLHVPXAudioCodecOpus];
        _filters.encoderItem = _encoderItem;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self _initializePopUps];
    _filters = [SLHFiltersController filtersController];
}

- (NSArray *)arguments {
    SLHPreferences *prefs = SLHPreferences.preferences;
    if (!prefs.hasFFmpeg) {
        NSLog(@"%s: ffmpeg file path is not set", __PRETTY_FUNCTION__);
        return nil;
    }
    NSString *ffmpegPath = prefs.ffmpegPath;
    
    SLHEncoderVPXOptions *options = (id)_encoderItem.videoOptions;
    TimeInterval ti = _encoderItem.interval;
    NSMutableArray *args = @[  ffmpegPath, @"-nostdin", @"-hide_banner",
                               SLHEncoderMediaOverwriteFilesKey,
                               @"-ss", @(ti.start).stringValue,
                               @"-i", _encoderItem.playerItem.filePath,
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

- (void)setDictionaryRepresentation:(NSDictionary *)dict {
    super.dictionaryRepresentation = dict;
    SLHEncoderVPXOptions *opts = (id)_encoderItem.videoOptions;
    NSNumber *value = dict[SLHEncoderVideoVPXEnableTwoPassKey];
    if (value) {
        opts.twoPass = value.boolValue;
    }
    
    value = dict[SLHEncoderVideoVPXEnableCRFKey];
    if (value) {
        opts.enableCRF = value.boolValue;
    }
    
    value = dict[SLHEncoderVideoVPXQualityKey];
    if (value) {
        SLHVPXQualityType quality = value.unsignedIntegerValue;
        opts.vpxQuality = quality;
        [_qualityPopUp selectItemWithTag:quality];
    }
    
    value = dict[SLHEncoderVideoVPXSpeedKey];
    if (value) {
        opts.speed = value.integerValue;
    }
    
    value = dict[SLHEncoderVideoVPXLagInFramesKey];
    if (value) {
        opts.lagInFrames = value.unsignedIntegerValue;
    }
    
    value = dict[SLHEncoderVideoVPXAutoAltRefKey];
    if (value) {
        opts.enableAltRef = value.boolValue;
    }
    
    value = dict[SLHEncoderVideoVPXUseVorbisAudioKey];
    if (value) {
        BOOL useVorbis = value.boolValue;
        opts.useVorbisAudio = useVorbis;
        SLHVPXAudioCodecType codecTag = (useVorbis) ? SLHVPXAudioCodecVorbis : SLHVPXAudioCodecOpus;
        [_audioCodecPopUp selectItemWithTag:codecTag];
    } else {
        opts.useVorbisAudio = NO;
        [_audioCodecPopUp selectItemWithTag:SLHVPXAudioCodecOpus];
    }
    
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dict = super.dictionaryRepresentation.mutableCopy;
    SLHEncoderVPXOptions *opts = (id)_encoderItem.videoOptions;
    dict[SLHEncoderVideoVPXEnableTwoPassKey] = @(opts.twoPass);
    dict[SLHEncoderVideoVPXEnableCRFKey] = @(opts.enableCRF);
    dict[SLHEncoderVideoVPXQualityKey] = @(opts.vpxQuality);
    dict[SLHEncoderVideoVPXSpeedKey] = @(opts.speed);
    dict[SLHEncoderVideoVPXLagInFramesKey] = @(opts.lagInFrames);
    dict[SLHEncoderVideoVPXAutoAltRefKey] = @(opts.enableAltRef);
    dict[SLHEncoderVideoVPXUseVorbisAudioKey] = @(opts.useVorbisAudio);
    return dict;
}

#pragma mark - IBActions

- (IBAction)audioCodecDidChange:(NSPopUpButton *)sender {
    if (sender.selectedTag == SLHVPXAudioCodecOpus) {
        _options.useVorbisAudio = NO;
        _encoderItem.audioOptions.codecName = @"libopus";
    } else {
        _options.useVorbisAudio = YES;
        _encoderItem.audioOptions.codecName = @"libvorbis";
    }
}

- (IBAction)qualityDidChange:(NSPopUpButton *)sender {
    ((SLHEncoderVPXOptions *)_encoderItem.videoOptions).vpxQuality = sender.selectedTag;
}

- (IBAction)channelsDidChange:(NSPopUpButton *)sender {
    _encoderItem.audioOptions.numberOfChannels = sender.selectedTag;
}

- (IBAction)widthDidChange:(id)sender {
    NSInteger videoIdx = _encoderItem.videoStreamIndex;
    if (_keepAspectRatio && videoIdx > -1) {
        NSSize size = _encoderItem.playerItem.tracks[videoIdx].videoSize;
        double aspect = size.width / size.height;
        SLHEncoderItemOptions *options = _encoderItem.videoOptions;
        options.videoHeight = options.videoWidth / aspect;
    }
}

- (IBAction)heightDidChange:(id)sender {
    NSInteger videoIdx = _encoderItem.videoStreamIndex;
    if (_keepAspectRatio && videoIdx > -1) {
        NSSize size = _encoderItem.playerItem.tracks[videoIdx].videoSize;
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
    {   // audioCodecPopUp
        menu = _audioCodecPopUp.menu;
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"Opus" action:nil keyEquivalent:@""];
        menuItem.tag = SLHVPXAudioCodecOpus;
        [menu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"Vorbis" action:nil keyEquivalent:@""];
        menuItem.tag = SLHVPXAudioCodecVorbis;
        [menu addItem:menuItem];
        
    }

}

- (NSArray *)audioArguments {
    SLHEncoderItemOptions *audioOpts = _encoderItem.audioOptions;
    NSString *bitrateTypeKey;
    NSString *bitrateValue;
    if (_options.useVorbisAudio) {
        bitrateTypeKey = SLHEncoderAudioQualityKey;
        bitrateValue = @(audioOpts.quality).stringValue;
    } else {
        bitrateTypeKey = SLHEncoderAudioBitrateKey;
        bitrateValue = @(audioOpts.bitRate * 1000).stringValue;
    }
    NSArray *args = @[
                      SLHEncoderAudioCodecKey, audioOpts.codecName,
                      bitrateTypeKey, bitrateValue,
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
    
    SLHVPXQualityType quality = options.vpxQuality;
    if (quality != SLHVPXQualityAuto) {
        
        [args addObject:SLHEncoderVideoVPXQualityKey];
        switch (quality) {
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
    if (_encoderItem == nil) {
        return self.noSelectionView;
    }
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
            view = [super encoderSettings:enc viewForTab:tab];
            break;
    }
    return view;
}

@end
