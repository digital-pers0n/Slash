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

- (id)copyWithZone:(NSZone *)zone {
    typeof(self) obj = [super copyWithZone:zone];
    obj->_bitRate = _bitRate;
    return obj;
}

@end
