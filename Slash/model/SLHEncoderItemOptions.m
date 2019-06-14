//
//  SLHEncoderItemOptions.m
//  Slash
//
//  Created by Terminator on 2019/03/01.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHEncoderItemOptions.h"

@implementation SLHEncoderItemOptions


- (instancetype)initWithOptions:(SLHEncoderItemOptions *)options {
    self = [super init];
    if (self) {
        _codecName = options.codecName.copy;
        _scale = options.scale;
        _videoWidth = options.videoWidth;
        _videoHeight = options.videoHeight;
        _bitRate = options.bitRate;
        _maxBitrate = options.maxBitrate;
        _crf = options.crf;
        _maxGopSize = options.maxGopSize;
        _sampleRate = options.sampleRate;
        _numberOfChannels = options.numberOfChannels;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    SLHEncoderItemOptions *item = [[self.class allocWithZone:zone] init];
    item->_codecName = _codecName.copy;
    item->_scale = _scale;
    item->_videoWidth = _videoWidth;
    item->_videoHeight = _videoHeight;
    item->_bitRate = _bitRate;
    item->_maxBitrate = _maxBitrate;
    item->_crf = _crf;
    item->_maxGopSize = _maxGopSize;
    item->_sampleRate = _sampleRate;
    item->_numberOfChannels = _numberOfChannels;
    return item;
}

@end
