//
//  SLHEncoderItemOptions.m
//  Slash
//
//  Created by Terminator on 2019/03/01.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHEncoderItemOptions.h"

@implementation SLHEncoderItemOptions

- (id)copyWithZone:(NSZone *)zone {
    SLHEncoderItemOptions *item = [[self.class allocWithZone:zone] init];
    item->_codecName = _codecName.copy;
    item->_videoWidth = _videoWidth;
    item->_videoHeight = _videoHeight;
    item->_bitRate = _bitRate;
    item->_maxBitrate = _maxBitrate;
    item->_crf = _crf;
    item->_sampleRate = _sampleRate;
    item->_numberOfChannels = _numberOfChannels;
    return item;
}

@end
