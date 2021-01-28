//
//  SLTH264EncoderSettings.m
//  Slash
//
//  Created by Terminator on 2020/08/06.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLTH264EncoderSettings.h"
#import "MPVKitDefines.h"

OBJC_DIRECT_MEMBERS
@implementation SLTH264EncoderSettings

@dynamic videoSettings, audioSettings;

+ (NSArray<NSString *> *)allowedContainers {
    return @[ @"mp4", @"mkv", @"m4v", @"mov" ];
}

- (id)copyWithZone:(NSZone *)zone {
    typeof(self) obj = [super copyWithZone:zone];
    obj->_enableCRFEncoding = _enableCRFEncoding;
    obj->_enableTwoPassEncoding = _enableCRFEncoding;
    return obj;
}

- (BOOL)allowsTwoPassEncoding {
    return YES;
}

- (NSArray<NSString *> *)firstPassArguments {
    if (_enableTwoPassEncoding &&
        !self.enableVideoPassThrough &&
        self.videoSettings.streamIndex >= 0) {
        NSMutableArray *args = [self commonArguments];
        [args addObject:@"-pass"];
        [args addObject:@"1"];
        return args;
    }
    return nil;
}

- (NSArray *)videoArguments {
    SLTH264VideoSettings *settings = self.videoSettings;
    if (settings.streamIndex < 0) {
        return settings.ignoredStreamArguments;
    }
    
    if (self.enableVideoPassThrough) {
        return settings.passThroughArguments;
    }
    
    if (_enableCRFEncoding && !_enableTwoPassEncoding) {
        return settings.crfArguments;
    }
    return settings.arguments;
}

- (NSArray *)audioArguments {
    SLTH264AudioSettings *settings = self.audioSettings;
    if (settings.streamIndex < 0) {
        return settings.ignoredStreamArguments;
    }
    
    if (self.enableAudioPassThrough) {
        return settings.passThroughArguments;
    }
    return settings.arguments;
}

- (NSArray *)subtitlesArguments {
    SLTSubtitlesSettings *settings = self.subtitlesSettings;
    if (settings.streamIndex < 0) {
        return settings.ignoredStreamArguments;
    }
    
    if ([self.containerName isEqualToString:@"mkv"]) {
        return settings.passThroughArguments;
    }
    return settings.arguments;
}

- (NSMutableArray<NSString *>*)commonArguments {
    NSMutableArray *args = [NSMutableArray array];
    [args addObjectsFromArray:[self videoArguments]];
    [args addObjectsFromArray:[self audioArguments]];
    [args addObjectsFromArray:[self subtitlesArguments]];
    return args;
}

- (NSArray<NSString *> *)arguments {
    NSMutableArray *args = [self commonArguments];
    if (_enableTwoPassEncoding) {
        [args addObject:@"-pass"];
        [args addObject:@"2"];
    }
    return args;
}

@end

OBJC_DIRECT_MEMBERS
@implementation SLTH264VideoSettings

+ (NSArray<NSString *> *)allowedPresets {
    return @[ @"ultrafast", @"superfast", @"veryfast", @"faster", @"fast",
              @"medium", @"slow", @"slower", @"veryslow", @"placebo" ];
}

+ (NSArray<NSString *> *)allowedProfiles {
    return @[ @"baseline", @"main", @"high" ];
}

+ (NSArray<NSString *> *)allowedLevels {
    return @[ @"1.0", @"1.1", @"1.2", @"1.3", @"2.0", @"2.1", @"2.2", @"3.0",
              @"3.1", @"3.2", @"4.0", @"4.1", @"4.2", @"5.0", @"5.1" ];
}

+ (NSArray<NSString *> *)allowedTunes {
    return @[ @"film", @"animation", @"grain", @"stillimage", @"psnr", @"ssim"];
}

- (instancetype)initWithStreamIndex:(NSInteger)idx {
    return [super initWithCodecName:@"libx264" streamIndex:idx];
}

- (instancetype)initWithVideoSettings:(SLTVideoSettings *)video {
    self = [super initWithVideoSettings:video];
    _codecName = @"libx264";
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    typeof(self) obj = [super copyWithZone:zone];
    obj->_maxRate = _maxRate;
    obj->_crf = _crf;
    obj->_preset = _preset.copy;
    obj->_profile = _profile.copy;
    obj->_level = _level.copy;
    obj->_tune = _tune.copy;
    obj->_enableFastdecode = _enableFastdecode;
    obj->_enableZerolatency = _enableZerolatency;
    obj->_enableFaststart = _enableFaststart;
    obj->_lookAhead = _lookAhead;
    return obj;
}

- (NSString *)tuneArgumentString {
    NSString *val = nil;
    if (_tune) {
        val = [NSString stringWithFormat:@"%@%@%@", _tune,
                                 _enableFastdecode ? @",fastdecode" : @"",
                                 _enableZerolatency ? @",zerolatency" : @""];
    } else {
        if (_enableFastdecode) {
            val = _enableZerolatency ? @"fastdecode,zerolatency": @"fastdecode";
        } else if (_enableZerolatency) {
            val = @"zerolatency";
        }
    }
    return val;
}

- (NSArray<NSString *> *)argumentsWithArray:(NSMutableArray *)args {
    if (_maxrate) {
        [args addObject:@"-maxrate"];
        [args addObject:@(_maxRate).stringValue];
        [args addObject:@"-bufsize"];
        [args addObject:@(_maxRate * 2).stringValue];
    }
    if (_preset) {
        [args addObject:@"-preset"];
        [args addObject:_preset];
    }
    if (_profile) {
        [args addObject:@"-profile:v"];
        [args addObject:_profile];
    }
    if (_level) {
        [args addObject:@"-level:v"];
        [args addObject:_level];
    }
    NSString *value = [self tuneArgumentString];
    if (value) {
        [args addObject:@"-tune"];
        [args addObject:value];
    }
    if (_enableFaststart) {
        [args addObject:@"-movflags"];
        [args addObject:@"+faststart"];
    }
    [args addObject:@"-rc-lookahead"];
    [args addObject:@(_lookAhead).stringValue];
    return args;
}

- (NSArray<NSString *> *)arguments {
    return [self argumentsWithArray:super.arguments.mutableCopy];
}

- (NSArray<NSString *> *)crfArguments {
    NSMutableArray *args = super.arguments.mutableCopy;
    [args addObject:@"-crf"];
    [args addObject:@(_crf).stringValue];
    return [self argumentsWithArray:args];
}

@end

@implementation SLTH264AudioSettings

- (instancetype)initWithStreamIndex:(NSInteger)idx {
    return [super initWithCodecName:@"aac" streamIndex:idx];
}

- (instancetype)initWithAudioSettings:(SLTAudioSettings *)audio {
    self = [super initWithAudioSettings:audio];
    _codecName = @"aac";
    return self;
}

@end
