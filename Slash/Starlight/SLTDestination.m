//
//  SLTDestination.m
//  Slash
//
//  Created by Terminator on 2020/07/30.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLTDestination.h"

#import "SLTDefines.h"
#import "SLTEncoderSettings.h"
#import "SLTMediaSettings.h"
#import "SLTObserver.h"
#import "SLTUtils.h"

@interface SLTDestination () {
    SLTObserver *_observer;
}
@property (nonatomic, readwrite) CGFloat duration;
@property (nonatomic, readwrite) int64_t estimatedFileSize;
@end

@implementation SLTDestination

+ (instancetype)destinationWithPath:(NSString *)path
                           settings:(SLTEncoderSettings *)settings {
    return [[self alloc] initWithPath:path settings:settings];
}

- (instancetype)initWithPath:(NSString *)path
                    settings:(SLTEncoderSettings *)settings {
    self = [super init];
    if (self) {
        _filePath = path;
        _settings = settings;
        _videoFilters = @[];
        _audioFilters = @[];
        _metadata = @{};
        [self startObserving];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    typeof(self) obj = [[self.class allocWithZone:zone] init];
    obj->_filePath = _filePath.copy;
    obj->_settings = _settings.copy;
    obj->_videoFilters = _videoFilters.copy;
    obj->_audioFilters = _audioFilters.copy;
    obj->_metadata = _metadata.copy;
    obj->_startTime = _startTime;
    obj->_endTime = _endTime;
    [obj startObserving];
    return obj;
}

- (void)dealloc {
    [self stopObserving];
}

- (void)setFileName:(NSString *)fileName {
    id path = _filePath.stringByDeletingLastPathComponent;
    self.filePath = [path stringByAppendingPathComponent:fileName];
}

- (NSString *)fileName {
    return _filePath.lastPathComponent;
}

- (BOOL)validateFileName:(id *)valueRef error:(NSError **)outError {
    return SLTValidateFileName(*valueRef, outError);
}

- (SLTTimeInterval)selectionRange {
    return (SLTTimeInterval){ .start = _startTime, .end = _endTime };
}

- (void)setSelectionRange:(SLTTimeInterval)selectionRange {
    self.startTime = selectionRange.start;
    self.endTime = selectionRange.end;
}

#pragma mark - KVO

- (void)startObserving {
    __unsafe_unretained typeof(self) u = self;
    id array = @[ KVP(self, settings.videoSettings.bitRate),
                  KVP(self, settings.audioSettings.bitRate),
                  KVP(self, settings.audioSettings.streamIndex),
                  KVP(self, settings.videoSettings.streamIndex),
                  KVP(self, settings.enableAudioPassThrough),
                  KVP(self, settings.enableVideoPassThrough),
                  KVP(self, startTime), KVP(self, endTime) ];
    
    _observer = [self observe:self keyPaths:array options:0 handler:
    ^(NSString * _Nonnull keyPath, NSDictionary * _Nonnull change)
     {
         int64_t videoBitrate = 0, audioBitrate = 0;
         SLTEncoderSettings *settings = u->_settings;
         SLTAudioSettings *audio = settings.audioSettings;
         SLTVideoSettings *video = settings.videoSettings;
         if (video->_streamIndex > -1) {
             if (settings.enableVideoPassThrough) {
                 videoBitrate = u->_dataSource.desiredVideoBitrate;
             } else {
                 videoBitrate = video->_bitRate;
             }
         }
         if (audio->_streamIndex > -1) {
             if (settings.enableAudioPassThrough) {
                 audioBitrate = u->_dataSource.desiredAudioBitrate;
             } else {
                 audioBitrate = audio->_bitRate;
             }
         }
         const double duration =  u->_endTime - u->_startTime;
         u.estimatedFileSize = (videoBitrate + audioBitrate) * duration / 8192;
         self.duration = duration;
     }];
}

- (void)stopObserving {
    _observer = nil;
}

@end
