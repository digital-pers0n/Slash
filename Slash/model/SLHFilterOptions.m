//
//  SLHFilterOptions.m
//  Slash
//
//  Created by Terminator on 2019/03/26.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHFilterOptions.h"

@implementation SLHFilterOptions

- (id)copyWithZone:(NSZone *)zone {
    
    SLHFilterOptions *copy = [[self.class allocWithZone:zone] init];
    copy->_enableVideoFilters = _enableVideoFilters;
    copy->_videoCropX = _videoCropX;
    copy->_videoCropY = _videoCropY;
    copy->_videoCropWidth = _videoCropWidth;
    copy->_videoCropHeight = _videoCropHeight;
    copy->_videoDeinterlace = _videoDeinterlace;
    
    copy->_enableAudioFilters = _enableAudioFilters;
    copy->_audioFadeIn = _audioFadeIn;
    copy->_audioFadeOut = _audioFadeOut;
    copy->_audioPreamp = _audioPreamp;
    
    return copy;
}

@end
