//
//  MPVPlayerItem.m
//  Slash
//
//  Created by Terminator on 2019/10/21.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "MPVPlayerItem.h"
#import "MPVMetadataItem.h"
#import "MPVPlayerItemTrack.h"
#import <libavformat/avformat.h>
#import <libavutil/avutil.h>

NSString * const MPVPlayerItemErrorDomain = @"com.home.mpvPlayerItem.ErrorDomain";

@interface MPVPlayerItem () {
    AVFormatContext *_av_format;
}


@end

@implementation MPVPlayerItem

#pragma mark - Initialization

+ (instancetype)playerItemWithPath:(NSString *)path {
    return [[MPVPlayerItem alloc] initWithPath:path];
}

+ (instancetype)playerItemWithURL:(NSURL *)url {
    return [[MPVPlayerItem alloc] initWithURL:url];
}

- (instancetype)initWithPath:(NSString *)path {
    return [self initWithURL:[NSURL fileURLWithPath:path]];
}

- (instancetype)initWithURL:(NSURL *)url {
    
    self = [super init];
    
    if (self) {
        
        _url = url;
        
        if ([self createAVFormat] != 0) {
            return self;
        }
        
        _bitRate = _av_format->bit_rate;
        if (_av_format->duration == AV_NOPTS_VALUE) {
            _duration = 1;
        } else {
            _duration = _av_format->duration / (double)AV_TIME_BASE;
        }
        _formatName = @(_av_format->iformat->name);
        
        if (url.fileURL) {
            
            NSError *error = nil;
            NSNumber *value = nil;
            [url getResourceValue:&value forKey:NSURLFileSizeKey error:&error];
            
            if (error) {
                
               NSLog(@"Failed to read file size of '%@', using estimate instead\n%@", url, error.localizedDescription);
                _fileSize = _bitRate * _duration / 8192 * 1024;
                
            } else {
                
                _fileSize = value.unsignedLongLongValue;
            }
            
        } else {
            
            _fileSize = _bitRate * _duration / 8192 * 1024;
        }
     
        [self readStreams];
        [self readMetadata];
        
        _status = MPVPlayerItemStatusReadyToPlay;
        
#ifdef DEBUG
        puts("-------------");
        printf("         Url: %s\n", _av_format->url);
        printf("    Duration: %g\n", _av_format->duration / (double)AV_TIME_BASE);
        printf("    Bit Rate: %lli\n", _av_format->bit_rate);
        printf("# of Streams: %u\n", _av_format->nb_streams);
        printf("   file size: %llu\n", _fileSize);
        printf(" format name: %s\n", _av_format->iformat->name);
        printf("   long name: %s\n", _av_format->iformat->long_name);
        printf("  extensions: %s\n", _av_format->iformat->extensions);
        printf("   mime type: %s\n", _av_format->iformat->mime_type);
        puts("-------------");
#endif

    }
    
    return self;
}

- (void)dealloc {
    if (_av_format) {
        avformat_close_input(&_av_format);
        _av_format = nil;
    }
}

- (int)createAVFormat {
    
    _av_format = nil;
    int error;
    const char *url;
    
    if (_url.fileURL) {
        url = _url.fileSystemRepresentation;
    } else {
        url = _url.absoluteString.UTF8String;
    }
    
    error = avformat_open_input(&_av_format, url, nil, nil);
    
    if (error) {
        goto bail;
    }
    
    error = avformat_find_stream_info(_av_format, nil);
    
bail:
    
    if (error) {
        _status = MPVPlayerItemStatusFailed;
        _error = [NSError errorWithDomain:MPVPlayerItemErrorDomain
                                     code:error
                                 userInfo:@{
                                            NSLocalizedDescriptionKey: @(av_error_string(error)),
                                            NSURLErrorKey: _url }];
        if (_av_format) {
            avformat_close_input(&_av_format);
        }
        _av_format = nil;
        return -1;
    }
    
    return 0;
}

- (void)readStreams {
    
    NSMutableArray *result = [NSMutableArray new];
    
    for (int i = 0; i < _av_format->nb_streams; i++) {
        MPVPlayerItemTrack *track = [[MPVPlayerItemTrack alloc] initWithFormat:_av_format stream:_av_format->streams[i]];
        [result addObject:track];
        
        switch (_av_format->streams[i]->codecpar->codec_type) {
                
            case AVMEDIA_TYPE_VIDEO:
                _hasVideoStreams = YES;
                break;
                
            case AVMEDIA_TYPE_AUDIO:
                _hasAudioStreams = YES;
                break;
                
            default:
                break;
        }
    }
    if (_hasVideoStreams) {
        int idx = av_find_best_stream(_av_format, AVMEDIA_TYPE_VIDEO,
                                      -1, -1, NULL, 0);
        if (idx >= 0) {
            _bestVideoTrack = result[idx];
        }
    }
    
    
    if (_hasAudioStreams) {
        int idx = av_find_best_stream(_av_format, AVMEDIA_TYPE_AUDIO,
                                      -1, -1, NULL, 0);
        if (idx >= 0) {
            _bestAudioTrack = result[idx];
        }
    }
    
    _tracks = result;
}

- (void)readMetadata {
    
    AVDictionaryEntry *pair = nil;
    NSMutableArray *result = [NSMutableArray new];
    
    while ((pair = av_dict_get(_av_format->metadata, "", pair, AV_DICT_IGNORE_SUFFIX))) {
        [result addObject:[[MPVMetadataItem alloc] initWithIdentifier:@(pair->key) value:@(pair->value)]];
    }
    
    _metadata = result;
}

static const char *av_error_string(int error_code) {
    static char buffer[AV_ERROR_MAX_STRING_SIZE];
    av_strerror(error_code, buffer, AV_ERROR_MAX_STRING_SIZE);
    return buffer;
}

#pragma mark - Properties

- (NSString *)filePath {
    return _url.path;
}

@end
