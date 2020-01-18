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
#import "SLHMediaItem.h"
#import "SLHMediaItemTrack.h"
#import "SLHEncoderItemMetadata.h"
#import "SLHPreferences.h"

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
                *const SLHEncoderVideoCodecKey,
                *const SLHEncoderVideoBitrateKey,
                *const SLHEncoderVideoMaxBitrateKey,
                *const SLHEncoderVideoBufsizeKey,
                *const SLHEncoderVideoCRFBitrateKey,
                *const SLHEncoderVideoAspectRatioKey,
                *const SLHEncoderVideoPixelFormatKey,
                *const SLHEncoderVideoScaleSizeKey,
                *const SLHEncoderVideoVPXSpeedKey,
                *const SLHEncoderVideoVPXLagInFramesKey,
                *const SLHEncoderVideoVPXQualityKey,
                *const SLHEncoderVideoVP9TileColumnsKey,
                *const SLHEncoderVideoVP9TileRowsKey,
                *const SLHEncoderVideoVP9FrameParallelKey,
                *const SLHEncoderVideoVP9RowMTKey;

extern NSString *const SLHEncoderFormatDidChangeNotification;

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
        _vpxFmt.cpuUsedMinValue = -8;
        _vpxFmt.cpuUsedMaxValue = 8;
        [self.view setNeedsDisplay:YES];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(formatDidChange:) name:SLHEncoderFormatDidChangeNotification object:nil];
    }
    return self;
}

- (void)setEncoderItem:(SLHEncoderItem *)encoderItem {
    SLHEncoderVP9Options *videoOptions = (id)encoderItem.videoOptions;
    SLHEncoderItemOptions *audioOptions = encoderItem.audioOptions;
    
    if (![videoOptions isKindOfClass:[SLHEncoderVP9Options class]]) {
        videoOptions = [[SLHEncoderVP9Options alloc] initWithOptions:videoOptions];
        videoOptions.speed = 0;
        videoOptions.vpxQuality = SLHVPXQualityAuto;
        videoOptions.twoPass = NO;
        videoOptions.enableCRF = NO;
        videoOptions.lagInFrames = 25;
        videoOptions.enableAltRef = YES;
        videoOptions.crf = 25;
        videoOptions.maxGopSize = 128;
        videoOptions.codecName = @"libvpx-vp9";
        videoOptions.row_mt = YES;
        videoOptions.frame_parallel = NO;
        videoOptions.tile_columns = 6;
        videoOptions.tile_rows = 2;
        encoderItem.videoOptions = videoOptions;
        encoderItem.container = @"webm";
        NSString *outputFileName = encoderItem.outputFileName;
        outputFileName = [outputFileName stringByDeletingPathExtension];
        outputFileName = [outputFileName stringByAppendingPathExtension:@"webm"];
        encoderItem.outputFileName = outputFileName;
        
        audioOptions.codecName = @"libopus";
        NSUInteger aBitRate = audioOptions.bitRate;
        audioOptions.bitRate = (aBitRate) ? aBitRate : 128;
        audioOptions.numberOfChannels = 2;
        audioOptions.quality = 3;
    }
    self.videoOptions = videoOptions;
    _vpxFmt.encoderItem = encoderItem;
}

- (SLHEncoderItem *)encoderItem {
    return _vpxFmt.encoderItem;
}

- (NSArray<NSArray *> *)arguments {
    NSString *ffmpegPath = SLHPreferences.preferences.ffmpegPath;
    if (!ffmpegPath) {
        NSLog(@"%s: ffmpeg file path is not set", __PRETTY_FUNCTION__);
        return nil;
    }
    SLHEncoderItem *_encoderItem = _vpxFmt.encoderItem;
    
    SLHEncoderVPXOptions *options = _videoOptions;
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
        [videoArgs addObjectsFromArray:_vpxFmt.videoArguments];
        [videoArgs addObjectsFromArray:self.videoArguments];
    } else {
        [videoArgs addObject:SLHEncoderMediaNoVideoKey ];
    }
    
    NSMutableArray *audioArgs = NSMutableArray.new;
    if (_encoderItem.audioStreamIndex >= 0) {
        [audioArgs addObject:SLHEncoderMediaMapKey];
        [audioArgs addObject:[NSString stringWithFormat:@"0:%li", _encoderItem.audioStreamIndex]];
        [audioArgs addObjectsFromArray:_vpxFmt.audioArguments];
    } else {
        [audioArgs addObject:SLHEncoderMediaNoAudioKey ];
    }
    
    NSArray *filterArgs = _vpxFmt.filters.arguments;
    NSMutableArray *output = NSMutableArray.new;
    if (options.twoPass) {
        extern char *g_temp_dir;
        [args addObject:SLHEncoderMediaPassLogKey];
        [args addObject:@(g_temp_dir)];
        [args addObject:SLHEncoderMediaPassKey];
        NSMutableArray *passOne = args.mutableCopy;
        [passOne addObject:@"1"];
        [passOne addObjectsFromArray:_vpxFmt.firstPassArguments];
        [passOne addObjectsFromArray:self.videoArguments];
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

- (NSArray *)videoArguments {
    return @[SLHEncoderVideoVP9TileColumnsKey, @(_videoOptions.tile_columns).stringValue,
                      SLHEncoderVideoVP9TileRowsKey, @(_videoOptions.tile_rows).stringValue,
                      SLHEncoderVideoVP9FrameParallelKey, @(_videoOptions.frame_parallel).stringValue,
                      SLHEncoderVideoVP9RowMTKey, @(_videoOptions.row_mt).stringValue];
    
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

- (void)setDictionaryRepresentation:(NSDictionary *)dict {
    _vpxFmt.dictionaryRepresentation = dict;
    SLHEncoderVP9Options *opts = _videoOptions;
    
    NSNumber *value = dict[SLHEncoderVideoVP9TileColumnsKey];
    if (value) {
        opts.tile_columns = value.unsignedIntegerValue;
    }
    
    value = dict[SLHEncoderVideoVP9TileRowsKey];
    if (value) {
        opts.tile_rows = value.unsignedIntegerValue;
    }
    
    value = dict[SLHEncoderVideoVP9FrameParallelKey];
    if (value) {
        opts.frame_parallel = value.boolValue;
    }
    
    value = dict[SLHEncoderVideoVP9RowMTKey];
    if (value) {
        opts.row_mt = value.boolValue;
    }
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dict = _vpxFmt.dictionaryRepresentation.mutableCopy;
    SLHEncoderVP9Options *opts = _videoOptions;
    
    dict[SLHEncoderVideoVP9TileColumnsKey] = @(opts.tile_columns);
    dict[SLHEncoderVideoVP9TileRowsKey] = @(opts.tile_rows);
    dict[SLHEncoderVideoVP9FrameParallelKey] = @(opts.frame_parallel);
    dict[SLHEncoderVideoVP9RowMTKey] = @(opts.row_mt);
    
    return dict;
}

#pragma mark - SLHEncoderSettingsDelegate

- (NSView *)encoderSettings:(SLHEncoderSettings *)enc viewForTab:(SLHEncoderSettingsTab) tab {
    if (_vpxFmt.encoderItem == nil) {
        return _vpxFmt.noSelectionView;
    }
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
            view = [_vpxFmt encoderSettings:enc viewForTab:tab];
            break;
    }
    return view;
}

#pragma mark - NSNotification

- (void)formatDidChange:(NSNotification *)notification {
    SLHEncoderBaseFormat *fmt = notification.object;
    SLHEncoderItemOptions *opts = fmt.encoderItem.videoOptions;
    if (opts == _videoOptions) {
        if (fmt == self) {
            opts.codecName = @"libvpx-vp9";
        } else {
            opts.codecName = @"libvpx";
        }
    }
}

@end
