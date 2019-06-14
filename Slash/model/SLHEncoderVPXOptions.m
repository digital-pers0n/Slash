//
//  SLHEncoderVPXOptions.m
//  Slash
//
//  Created by Terminator on 2019/05/27.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHEncoderVPXOptions.h"

@implementation SLHEncoderVPXOptions

- (id)copyWithZone:(NSZone *)zone {
    SLHEncoderVPXOptions *obj = [super copyWithZone:zone];
    obj->_twoPass = _twoPass;
    obj->_enableCRF = _enableCRF;
    obj->_quality = _quality;
    obj->_speed = _speed;
    obj->_lagInFrames = _lagInFrames;
    obj->_enableAltRef = _enableAltRef;
    return obj;
}

@end
