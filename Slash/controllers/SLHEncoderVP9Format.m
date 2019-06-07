//
//  SLHEncoderVP9Format.m
//  Slash
//
//  Created by Terminator on 2019/06/05.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHEncoderVP9Format.h"
#import "SLHEncoderVP9Options.h"
#import "SLHEncoderVPXFormat.h"
#import "SLHFiltersController.h"
#import "SLHEncoderItem.h"
#import "SLHPreferences.h"

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
                *const SLHEncoderVideoVPXSpeedKey,
                *const SLHEncoderVideoVPXRcLookaheadKey,
                *const SLHEncoderVideoVPXQualityKey,
                *const SLHEncoderVideoVP9TileColumnsKey,
                *const SLHEncoderVideoVP9TileRowsKey,
                *const SLHEncoderVideoVP9FrameParallelKey,
                *const SLHEncoderVideoVP9RowMTKey;

@interface SLHEncoderVP9Format ()

@property SLHEncoderVP9Options *videoOptions;
@property IBOutlet NSView *localView;
@property SLHEncoderVPXFormat *vpxFmt;

@end

@implementation SLHEncoderVP9Format

- (NSString *)nibName {
    return @"SLHEncoderVP9Format";
}

- (NSString *)formatName {
    return @"VP9";
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _vpxFmt = [[SLHEncoderVPXFormat alloc] init];
    }
    return self;
}

- (void)setEncoderItem:(SLHEncoderItem *)encoderItem {
    SLHEncoderVP9Options *videoOptions = (id)encoderItem.videoOptions;
    SLHEncoderItemOptions *audioOptions = encoderItem.audioOptions;
    
    if (![videoOptions isKindOfClass:[SLHEncoderVP9Options class]]) {
        videoOptions = [[SLHEncoderVP9Options alloc] initWithOptions:videoOptions];
        videoOptions.speed = 0;
        videoOptions.quality = SLHVPXQualityAuto;
        videoOptions.twoPass = NO;
        videoOptions.enableCRF = NO;
        videoOptions.lookAhead = 25;
        videoOptions.enableAltRef = YES;
        videoOptions.crf = 25;
        videoOptions.codecName = @"libvpx-vp9";
        videoOptions.row_mt = YES;
        videoOptions.frame_parallel = YES;
        videoOptions.tile_columns = 6;
        videoOptions.tile_rows = 2;
        encoderItem.videoOptions = videoOptions;
        encoderItem.container = @"webm";
        NSString *outputFileName = encoderItem.outputFileName;
        outputFileName = [outputFileName stringByDeletingPathExtension];
        outputFileName = [outputFileName stringByAppendingPathExtension:@"webm"];
        encoderItem.outputFileName = outputFileName;
        
        audioOptions.codecName = @"libopus";
        audioOptions.bitRate = 128;
        audioOptions.numberOfChannels = 2;
    }
    _videoOptions = videoOptions;
    _vpxFmt.encoderItem = encoderItem;
}

- (SLHEncoderItem *)encoderItem {
    return _vpxFmt.encoderItem;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSView *videoView = _vpxFmt.view;
    NSRect frame = videoView.frame;
    NSRect localFrame = self.view.frame;
    frame.size.height = NSHeight(frame) + NSHeight(localFrame);
    videoView.frame = frame;
    [videoView addSubview:_localView];
}

#pragma mark - SLHEncoderSettingsDelegate

- (NSView *)encoderSettings:(SLHEncoderSettings *)enc viewForTab:(SLHEncoderSettingsTab) tab {
    NSView *view = nil;
    switch (tab) {
        case SLHEncoderSettingsVideoTab:
            view = _vpxFmt.videoView;
            break;
        case SLHEncoderSettingsAudioTab:
            view = _vpxFmt.audioView;
            break;
        case SLHEncoderSettingsFiltersTab:
            view = _vpxFmt.filters.view;
            break;
            
        default:
            break;
    }
    return view;
}

@end
