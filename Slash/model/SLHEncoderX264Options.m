//
//  SLHEncoderX264Options.m
//  Slash
//
//  Created by Terminator on 2019/03/18.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHEncoderX264Options.h"

@implementation SLHEncoderX264Options

- (instancetype)initWithOptions:(SLHEncoderItemOptions *)options {
    self = [super init];
    if (self) {
        self.codecName = options.codecName;
        self.videoWidth = options.videoWidth;
        self.videoHeight = options.videoHeight;
        self.bitRate = options.bitRate;
        self.maxBitrate = options.maxBitrate;
        self.crf = options.crf;
        self.sampleRate = options.sampleRate;
        self.numberOfChannels = options.numberOfChannels;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    SLHEncoderX264Options *obj = [super copyWithZone:zone];
    obj->_encodingType = _encodingType;
    obj->_presetType = _presetType;
    obj->_profileType = _profileType;
    obj->_tuneType = _tuneType;
    obj->_fastdecode = _fastdecode;
    obj->_zerolatency = _zerolatency;
    return obj;
}

@end
