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
    copy->_burnSubtitles = _burnSubtitles;
    copy->_subtitlesPath = _subtitlesPath.copy;
    copy->_forceSubtitlesStyle = _forceSubtitlesStyle;
    copy->_subtitlesStyle = _subtitlesStyle.copy;
    copy->_additionalVideoFiltersString = _additionalVideoFiltersString.copy;
    
    copy->_enableAudioFilters = _enableAudioFilters;
    copy->_audioFadeIn = _audioFadeIn;
    copy->_audioFadeOut = _audioFadeOut;
    copy->_audioPreamp = _audioPreamp;
    copy->_additionalAudioFiltersString = _additionalAudioFiltersString.copy;
    
    return copy;
}

- (NSRect)videoCropRect {
    return NSMakeRect(_videoCropX, _videoCropY,
                      _videoCropWidth, _videoCropHeight);
}

- (void)setVideoCropRect:(NSRect)videoCropRect {
    self.videoCropX = NSMinX(videoCropRect);
    self.videoCropY = NSMinY(videoCropRect);
    self.videoCropWidth = NSWidth(videoCropRect);
    self.videoCropHeight = NSHeight(videoCropRect);
}

@end
