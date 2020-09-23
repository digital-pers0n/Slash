//
//  SLTH264EncoderSettings.m
//  Slash
//
//  Created by Terminator on 2020/08/06.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLTH264EncoderSettings.h"
#import "MPVKitDefines.h"

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

- (instancetype)init {
    self = [super init];
    if (self) {
        self.videoSettings = [[SLTH264VideoSettings alloc] init];
        self.audioSettings = [[SLTH264AudioSettings alloc] init];
        self.subtitlesSettings = [[SLTSubtitlesSettings alloc] init];
        self.containerName = @"mp4";
    }
    return self;
}

- (BOOL)allowsTwoPassEncoding {
    return YES;
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

- (instancetype)init {
    self = [super init];
    if (self) {
        _codecName = @"libx264";
    }
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
    [args addObject:@"-maxrate"];
    [args addObject:@(_maxRate).stringValue];
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

- (instancetype)init {
    self = [super init];
    if (self) {
        _codecName = @"aac";
    }
    return self;
}

@end
