//
//  SLTEncoderSettings.m
//  Slash
//
//  Created by Terminator on 2020/08/02.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLTEncoderSettings.h"
#import "SLTMediaSettings.h"

@implementation SLTEncoderSettings

static NSString *SLTDefaultFFmpegPath = @"/usr/local/bin/ffmpeg";

+ (NSString *)ffmpegPath {
    return SLTDefaultFFmpegPath;
}

+ (void)setFfmpegPath:(NSString *)path {
    NSAssert(path, @"FFmpeg path cannot be nil.");
    SLTDefaultFFmpegPath = path.copy;
}

static NSInteger SLTDefaultNumberOfThreads = 0;

+ (NSInteger)numberOfThreads {
    return SLTDefaultNumberOfThreads;
}

+ (void)setNumberOfThreads:(NSInteger)threads {
    SLTDefaultNumberOfThreads = threads;
}

+ (NSArray<NSString *> *)allowedContainers {
    return @[];
}

- (instancetype)initWithVideo:(SLTVideoSettings *)video
                        audio:(SLTAudioSettings *)audio
                    subtitles:(SLTSubtitlesSettings *)subs {
    self = [super init];
    if (self) {
        _videoSettings = video;
        _audioSettings = audio;
        _subtitlesSettings = subs;
        _containerName = @"mkv";
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    SLTEncoderSettings *obj = [[self.class allocWithZone:zone] init];
    obj->_enableAudioPassThrough = _enableAudioPassThrough;
    obj->_enableVideoPassThrough = _enableVideoPassThrough;
    obj->_videoSettings = _videoSettings.copy;
    obj->_audioSettings = _audioSettings.copy;
    obj->_containerName = _containerName.copy;
    obj->_subtitlesSettings = _subtitlesSettings.copy;
    obj->_allowsTwoPassEncoding = _allowsTwoPassEncoding;
    return obj;
}

- (BOOL)allowsAudioFilters {
    return (!_enableAudioPassThrough && _audioSettings->_streamIndex >= 0);
}

- (BOOL)allowsVideoFilters {
    return (!_enableVideoPassThrough && _videoSettings->_streamIndex >= 0);
}

@end
