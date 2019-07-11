//
//  SLHEncoderX264Options.m
//  Slash
//
//  Created by Terminator on 2019/03/18.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHEncoderX264Options.h"

@implementation SLHEncoderX264Options

- (id)copyWithZone:(NSZone *)zone {
    SLHEncoderX264Options *obj = [super copyWithZone:zone];
    obj->_encodingType = _encodingType;
    obj->_presetType = _presetType;
    obj->_profileType = _profileType;
    obj->_levelType = _levelType;
    obj->_containerType = _containerType;
    obj->_tuneType = _tuneType;
    obj->_fastdecode = _fastdecode;
    obj->_zerolatency = _zerolatency;
    obj->_faststart = _faststart;
    obj->_lookAhead = _lookAhead;
    return obj;
}

@end
