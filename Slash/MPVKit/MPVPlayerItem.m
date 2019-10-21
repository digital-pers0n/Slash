//
//  MPVPlayerItem.m
//  Slash
//
//  Created by Terminator on 2019/10/21.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "MPVPlayerItem.h"
#import <libavformat/avformat.h>
#import <libavutil/avutil.h>

NSString * const MPVPlayerItemErrorDomain = @"com.home.mpvPlayerItem.ErrorDomain";

@interface MPVPlayerItem () {
    AVFormatContext *_av_format;
}


@end

@implementation MPVPlayerItem

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
        
        NSError *err = nil;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[url path] error:&err];
        if (err) {
            NSLog(@"Failed to read file attributes of '%@'\n%@", url, err.localizedDescription);
            _fileSize = 0;
        } else {
            _fileSize = attributes.fileSize;
        }
        
        _bitRate = _av_format->bit_rate;
        _duration = _av_format->duration / (double)AV_TIME_BASE;
        _formatName = @(_av_format->iformat->name);
        
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
    
    int error = avformat_open_input(&_av_format, _url.fileSystemRepresentation, nil, nil);
    
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
    _tracks = @[];
}

- (void)readMetadata {
    _metadata = @[];
}

static const char *av_error_string(int error_code) {
    static char buffer[AV_ERROR_MAX_STRING_SIZE];
    av_strerror(error_code, buffer, AV_ERROR_MAX_STRING_SIZE);
    return buffer;
}

@end
