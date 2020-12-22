//
//  SLTMediaSettings.m
//  Slash
//
//  Created by Terminator on 2020/08/02.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLTMediaSettings.h"

@implementation SLTMediaSettings

- (instancetype)initWithSettings:(SLTMediaSettings *)media {
    self = [super init];
    if (self) {
        _streamIndex = media->_streamIndex;
        _codecName = media->_codecName.copy;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    typeof(self) obj = [[[self class] allocWithZone:zone] init];
    obj->_streamIndex = _streamIndex;
    obj->_codecName = _codecName.copy;
    return obj;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _codecName = @"";
    }
    return self;
}

- (NSArray<NSString *> *)arguments {
    return nil;
}

- (NSArray<NSString *> *)passThroughArguments {
    return nil;
}

- (NSArray<NSString *> *)ignoredStreamArguments {
    return nil;
}

static NSString *SLTMapStreamIndex(NSInteger streamIndex) {
    char buffer[8];
    CFIndex length = snprintf(buffer, sizeof(buffer), "0:%li", streamIndex);
    return CFBridgingRelease(
           CFStringCreateWithBytes(kCFAllocatorDefault, (const UInt8 *)buffer,
                                   length, kCFStringEncodingUTF8,
                                   /* isExternalRepresentation */ NO));
}

@end

@implementation SLTAudioSettings

- (instancetype)initWithAudioSettings:(SLTAudioSettings *)audio {
    self = [super initWithSettings:audio];
    _bitRate = audio->_bitRate;
    _sampleRate = audio->_sampleRate;
    _numberOfChannels = audio->_numberOfChannels;
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    typeof(self) obj = [super copyWithZone:zone];
    obj->_bitRate = _bitRate;
    obj->_sampleRate = _sampleRate;
    obj->_numberOfChannels = _numberOfChannels;
    return obj;
}

- (NSArray<NSString *> *)arguments {
    return @[ @"-map", SLTMapStreamIndex(_streamIndex),
              @"-c:a", _codecName,
              @"-b:a", @(_bitRate).stringValue,
              @"-ar",  @(_sampleRate).stringValue,
              @"-ac",  @(_numberOfChannels).stringValue ];
}

- (NSArray<NSString *> *)passThroughArguments {
    return @[ @"-map", SLTMapStreamIndex(_streamIndex),
              @"-c:a", @"copy" ];
}

- (NSArray<NSString *> *)ignoredStreamArguments {
    return @[ @"-an" ];
}

@end

@implementation SLTVideoSettings

- (instancetype)initWithVideoSettings:(SLTVideoSettings *)video {
    self = [super initWithSettings:video];
    _bitRate = video->_bitRate;
    _pixelFormat = video->_pixelFormat.copy;
    _maxGopSize = video->_maxGopSize;
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    typeof(self) obj = [super copyWithZone:zone];
    obj->_bitRate = _bitRate;
    obj->_pixelFormat = _pixelFormat.copy;
    obj->_maxGopSize = _maxGopSize;
    return obj;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _pixelFormat = @"yuv420p";
    }
    return self;
}

- (NSArray<NSString *> *)arguments {
    return @[ @"-map",     SLTMapStreamIndex(_streamIndex),
              @"-c:v",     _codecName,
              @"-b:v",     @(_bitRate).stringValue,
              @"-pix_fmt", _pixelFormat,
              @"-g",       @(_maxGopSize).stringValue ];
}

- (NSArray<NSString *> *)passThroughArguments {
    return @[ @"-map", SLTMapStreamIndex(_streamIndex),
              @"-c:v", @"copy" ];
}

- (NSArray<NSString *> *)ignoredStreamArguments {
    return @[ @"-vn" ];
}

@end

@implementation SLTSubtitlesSettings

- (instancetype)init{
    self = [super init];
    if (self) {
        _codecName = @"mov_text";
    }
    return self;
}

- (NSArray<NSString *> *)arguments {
    return @[ @"-map", SLTMapStreamIndex(_streamIndex),
              @"-c:s", _codecName ];
}

- (NSArray<NSString *> *)passThroughArguments {
    return @[ @"-map", SLTMapStreamIndex(_streamIndex),
              @"-c:s", @"copy" ];
}

- (NSArray<NSString *> *)ignoredStreamArguments {
    return @[ @"-sn" ];
}

@end
