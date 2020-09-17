//
//  SLTH264EncoderSettings.m
//  Slash
//
//  Created by Terminator on 2020/08/06.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLTH264EncoderSettings.h"

@implementation SLTH264EncoderSettings

- (id)copyWithZone:(NSZone *)zone {
    typeof(self) obj = [super copyWithZone:zone];
    obj->_enableCRFEncoding = _enableCRFEncoding;
    obj->_enableTwoPassEncoding = _enableCRFEncoding;
    return obj;
}

@end

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

@end

@implementation SLTH264AudioSettings
@end
