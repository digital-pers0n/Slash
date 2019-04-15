//
//  SLHMediaItem.m
//  Slash
//
//  Created by Terminator on 2018/08/14.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import "SLHMediaItem.h"
#import "slh_media.h"
#import "slh_media_keys.h"
#import "SLHPreferences.h"
#import "SLHMediaItemTrack.h"
#import "SLHMetadataItem.h"

@interface SLHMediaItem () {
    Media *_media;
}

@end

@implementation SLHMediaItem

- (instancetype)init {
    @throw [NSException
            exceptionWithName:NSInternalInconsistencyException
            reason:@"Use initWithPath: instead"
            userInfo:nil];

}

+ (instancetype)mediaItemWithPath:(NSString *)path {
    return [[SLHMediaItem alloc] initWithPath:path];
}

- (instancetype)initWithPath:(NSString *)path {

    self = [super init];
    if (self) {
        _media = NULL;
        _filePath = path;
        [self _setUp];
    }
    return self;
}

- (void)_setUp {
    _status = SLHMediaItemStatusFailed;
    if (!_filePath) {
        _error = [[NSError alloc] initWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{NSLocalizedDescriptionKey : @"File path cannot be nil" }];
        return;
    }
    
    NSString *ffprobePath = [[NSUserDefaults standardUserDefaults] objectForKey:SLHPreferencesFFProbeFilePathKey];
    _media = malloc(sizeof(Media));
    int ret = media_init(_media, ffprobePath.UTF8String, _filePath.UTF8String);
    
    if (ret != 0) {
        _error = [[NSError alloc] initWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{ NSLocalizedDescriptionKey: @"Initialization Failed"}];
        return;
    }
    [self _setUpFormat];
    [self _setUpStreams];
    [self _setUpMetadata];
    
    _status = SLHMediaItemStatusReadyToPlay;
    
    media_destroy(_media);
    free(_media);
    
}

/**
 Convert a C-style string to an instance of NSString
 */
static inline NSString *_cstr2nsstr(const char *str) {
    return (str) ? [NSString stringWithUTF8String:str] : @"";
}

- (void)_setUpFormat {
    _formatName = _cstr2nsstr(media_format_name(_media));
    _fileSize = media_size(_media);
    _bitRate = media_bit_rate(_media);
    _duration = media_duration(_media);
    
}

- (void)_setUpStreams {
    size_t nb_streams = media_nb_streams(_media);
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:nb_streams];
    Stream *streams = media_streams(_media);
    
    for (int i = 0; i < nb_streams; i++) {
        Stream *stream = streams + i;
        
        SLHMediaItemTrack *track = [[SLHMediaItemTrack alloc]
                    initWithTrackIndex:stream_index(stream)
                             mediaType:(SLHMediaType)stream_codec_type(stream)
                             codecName:_cstr2nsstr(stream_get_value(stream, kMediaStreamCodecNameKey))
                       encodingProfile:_cstr2nsstr(stream_get_value(stream, kMediaStreamProfileKey))];
        
        if (stream_codec_type(stream) == CodecTypeVideo) {
            track.videoSize = NSMakeSize(strtod(stream_get_value(stream, kMediaStreamWidthKey), 0),
                                         strtod(stream_get_value(stream, kMediaStreamHeightKey), 0));
            track.pixelFormat = _cstr2nsstr(stream_get_value(stream, kMediaStreamPixFormatKey));
            
            // Get frame rate
            char *fps = stream_get_value(stream, kMediaStreamFramerateKey);
            if (fps) {
                //puts(fps);
                char *div;
                long fps_numerator = strtol(fps, &div, 10);
                long fps_denominator = 1;
                if (*div == '/') {
                    fps_denominator = strtol(div + 1, 0, 10);
                }
                track.frameRate = fps_numerator / (double)fps_denominator;
                //printf("fps: %.1f\n", track.frameRate);
                
            }
            
        } else if (stream_codec_type(stream) == CodecTypeAudio) {
            track.numberOfChannels = atoi(stream_get_value(stream, kMediaStreamChannelsKey));
            track.channelLayout = _cstr2nsstr(stream_get_value(stream, kMediaStreamChannelLayoutKey));
            track.sampleRate = _cstr2nsstr(stream_get_value(stream, kMediaStreamSampleRateKey));
        }
        char *lang = stream_get_value(stream, kMediaMetadataLanguageKey);
        track.language = (lang) ? [NSString stringWithUTF8String:lang] : @"und";
        track.bitRate = atoi(stream_get_value(stream, kMediaStreamBitRateKey));
        
        array[i] = track;
    }
    
    _tracks = array;
}

static inline BOOL _isTag(const char *str) {
    return (str[0] == 'T' && str[1] == 'A' && str[2] == 'G' && str[3] == ':');
}

- (void)_setUpMetadata {
    NSMutableArray *array = [NSMutableArray array];
    Dictionary *info = media_info(_media);
    size_t size = dict_size(info);
    char **keys = malloc(size * sizeof(char *));
    char **values = malloc(size * sizeof(char *));
    dict_get_keys_and_values(info, keys, (void **)values);
    
    for (size_t i = 0; i < size; i++) {
        char *key = keys[i];
        if (_isTag(key)) {
            char *val = values[i];
            SLHMetadataItem *item = [[SLHMetadataItem alloc]
                                     initWithIdentifier:_cstr2nsstr(key + 4)
                                                  value:_cstr2nsstr(val)];
            [array addObject:item];
        }
    }
    
    _metadata = array;
    
}

@end
