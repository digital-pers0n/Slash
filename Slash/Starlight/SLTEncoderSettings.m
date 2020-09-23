//
//  SLTEncoderSettings.m
//  Slash
//
//  Created by Terminator on 2020/08/02.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLTEncoderSettings.h"
#import "SLTMediaSettings.h"

@implementation SLTEncoderSettings

+ (NSArray<NSString *> *)allowedContainers {
    return @[];
}

- (id)copyWithZone:(NSZone *)zone {
    SLTEncoderSettings *obj = [[self.class allocWithZone:zone] init];
    obj->_enableAudioPassThrough = _enableAudioPassThrough;
    obj->_enableVideoPassThrough = _enableVideoPassThrough;
    obj->_videoSettings = _videoSettings.copy;
    obj->_audioSettings = _audioSettings.copy;
    obj->_containerName = _containerName.copy;
    obj->_subtitlesSettings = _subtitlesSettings.copy;
    obj->_allowsTwoPassEncoding = _allowsTwoPassEncoding;
    return obj;
}

@end
