//
//  SLHEncoderBaseFormat.m
//  Slash
//
//  Created by Terminator on 2018/11/16.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import "SLHEncoderBaseFormat.h"
#import "SLHEncoderItem.h"
#import "SLHEncoderItemOptions.h"

extern NSString *const SLHEncoderMediaContainerKey;
extern NSString *const SLHEncoderMediaNoSubtitlesKey;
extern NSString *const SLHEncoderMediaNoVideoKey;
extern NSString *const SLHEncoderMediaNoAudioKey;
extern NSString *const SLHEncoderVideoBitrateKey;
extern NSString *const SLHEncoderVideoMaxBitrateKey;
extern NSString *const SLHEncoderVideoCRFBitrateKey;
extern NSString *const SLHEncoderVideoCodecKey;
extern NSString *const SLHEncoderVideoScaleSizeKey;
extern NSString *const SLHEncoderVideoMaxGopSizeKey;
extern NSString *const SLHEncoderAudioCodecKey;
extern NSString *const SLHEncoderAudioBitrateKey;
extern NSString *const SLHEncoderAudioSampleRateKey;
extern NSString *const SLHEncoderAudioChannelsKey;

@interface SLHEncoderBaseFormat ()

@end

@implementation SLHEncoderBaseFormat

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)setDictionaryRepresentation:(NSDictionary *)dict {
    
    NSString *str = dict[SLHEncoderMediaContainerKey];
    if (str) {
        _encoderItem.container = str;
    }
    
    NSNumber *val = dict[SLHEncoderMediaNoSubtitlesKey];
    if (val) {
        _encoderItem.subtitlesStreamIndex = -1;
    }
    
    val = dict[SLHEncoderMediaNoVideoKey];
    if (val) {
        _encoderItem.videoStreamIndex = -1;
    }
    
    val = dict[SLHEncoderMediaNoAudioKey];
    if (val) {
        _encoderItem.audioStreamIndex = -1;
    }
    
    SLHEncoderItemOptions *opts = _encoderItem.videoOptions;
    
    val = dict[SLHEncoderVideoBitrateKey];
    if (val) {
        opts.bitRate = val.unsignedIntegerValue;
    }
    
    val = dict[SLHEncoderVideoMaxBitrateKey];
    if (val) {
        opts.maxBitrate = val.unsignedIntegerValue;
    }
    
    val =  dict[SLHEncoderVideoCRFBitrateKey];
    if (val) {
        opts.crf = val.unsignedIntegerValue;
    }
    
    str = dict[SLHEncoderVideoCodecKey];
    if (str) {
        opts.codecName = str;
    }
    
    str = dict[SLHEncoderVideoScaleSizeKey];
    if (str) {
        NSSize size = NSSizeFromString(str);
        opts.videoWidth = size.width;
        opts.videoHeight = size.height;
        opts.scale = YES;
    }
    
    val = dict[SLHEncoderVideoMaxGopSizeKey];
    if (val) {
        opts.maxGopSize = val.unsignedIntegerValue;
    }
    
    opts = _encoderItem.audioOptions;
    
    str = dict[SLHEncoderAudioCodecKey];
    if (str) {
        opts.codecName = str;
    }
    
    val = dict[SLHEncoderAudioBitrateKey];
    if (val) {
        opts.bitRate = val.unsignedIntegerValue;
    }
    
    val = dict[SLHEncoderAudioSampleRateKey];
    if (val) {
        opts.sampleRate = val.unsignedIntegerValue;
    }
    
    val = dict[SLHEncoderAudioChannelsKey];
    if (val) {
        opts.numberOfChannels = val.unsignedIntegerValue;
    }
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dict = NSMutableDictionary.new;
    NSString *str = _encoderItem.container;
    
    if (str) {
        dict[SLHEncoderMediaContainerKey] = str;
    }
    
    if (_encoderItem.subtitlesStreamIndex == -1) {
        dict[SLHEncoderMediaNoSubtitlesKey] = @(YES);
    }
    
    if (_encoderItem.videoStreamIndex == -1) {
        dict[SLHEncoderMediaNoVideoKey] = @(YES);
    }
    
    if (_encoderItem.audioStreamIndex == -1) {
        dict[SLHEncoderMediaNoAudioKey] = @(YES);
    }
    
    /* Video */
    SLHEncoderItemOptions *opts =  _encoderItem.videoOptions;
    
    dict[SLHEncoderVideoBitrateKey] = @(opts.bitRate);
    dict[SLHEncoderVideoMaxBitrateKey] = @(opts.maxBitrate);
    dict[SLHEncoderVideoCRFBitrateKey] = @(opts.crf);
    dict[SLHEncoderVideoMaxGopSizeKey] = @(opts.maxGopSize);
    
    str = opts.codecName;
    if (str) {
        dict[SLHEncoderVideoCodecKey] = str;
    }
    
    if (opts.scale) {
        str = NSStringFromSize(NSMakeSize(opts.videoWidth, opts.videoHeight));
        dict[SLHEncoderVideoScaleSizeKey] = str;
    }
    
    /* Audio */
    opts = _encoderItem.audioOptions;
    
    dict[SLHEncoderAudioBitrateKey] = @(opts.bitRate);
    dict[SLHEncoderAudioSampleRateKey] = @(opts.sampleRate);
    dict[SLHEncoderAudioChannelsKey] = @(opts.numberOfChannels);
    
    str = opts.codecName;
    if (str) {
        dict[SLHEncoderAudioCodecKey] = str;
    }
    
    return dict;
}

#pragma mark - SLHEncoderSettingsDelegate

- (NSView *)encoderSettings:(SLHEncoderSettings *)enc viewForTab:(SLHEncoderSettingsTab) tab {
    return nil;
}

@end
