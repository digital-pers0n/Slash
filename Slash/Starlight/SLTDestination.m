//
//  SLTDestination.m
//  Slash
//
//  Created by Terminator on 2020/07/30.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLTDestination.h"
#import "SLTEncoderSettings.h"

@implementation SLTDestination

- (id)copyWithZone:(NSZone *)zone {
    typeof(self) obj = [[self.class allocWithZone:zone] init];
    obj->_filePath = _filePath.copy;
    obj->_settings = _settings.copy;
    obj->_videoFilters = _videoFilters.copy;
    obj->_audioFilters = _audioFilters.copy;
    obj->_metadata = _metadata.copy;
    obj->_inPoint = _inPoint;
    obj->_outPoint = _outPoint;
    return obj;
}

- (void)setFileName:(NSString *)fileName {
    id path = _filePath.stringByDeletingLastPathComponent;
    self.filePath = [path stringByAppendingPathComponent:fileName];
}

- (NSString *)fileName {
    return _filePath.lastPathComponent;
}

@end
