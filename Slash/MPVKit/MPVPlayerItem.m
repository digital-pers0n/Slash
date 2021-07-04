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
#import "MPVKitDefines.h"
#import <libavformat/avformat.h>
#import <libavutil/avutil.h>

NSString * const MPVPlayerItemErrorDomain = @"com.home.mpvPlayerItem.ErrorDomain";

@interface MPVPlayerItem () {
    MPVPlayerItemTrack *_bestVideoTrack;
    MPVPlayerItemTrack *_bestAudioTrack;
}


@end

OBJC_DIRECT_MEMBERS
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
    if (!self) return nil;
    
    _url = url;
    AVFormatContext *avfc = [self createAVFormatWithURL:url];
    if (!avfc) return self;
    
    _bitRate = avfc->bit_rate;
    if (avfc->duration == AV_NOPTS_VALUE) {
        _duration = 1;
    } else {
        _duration = avfc->duration / (double)AV_TIME_BASE;
    }
    _formatName = @(avfc->iformat->name);
    
    if (url.fileURL) {
        NSError *error = nil;
        NSNumber *value = nil;
        [url getResourceValue:&value forKey:NSURLFileSizeKey error:&error];
        if (error) {
            NSLog(@"Failed to read file size of '%@', using estimate instead\n%@",
                  url, error.localizedDescription);
            _fileSize = _bitRate * _duration / 8192 * 1024;
            
        } else {
            _fileSize = value.unsignedLongLongValue;
        }
    } else {
        _fileSize = _bitRate * _duration / 8192 * 1024;
    }
    [self readStreams:avfc];
    [self readMetadata:avfc];
    _status = MPVPlayerItemStatusReadyToPlay;
    
#ifdef DEBUG
    puts("-------------");
    printf("         Url: %s\n", avfc->url);
    printf("    Duration: %g\n", avfc->duration / (double)AV_TIME_BASE);
    printf("    Bit Rate: %lli\n", avfc->bit_rate);
    printf("# of Streams: %u\n", avfc->nb_streams);
    printf("   file size: %llu\n", _fileSize);
    printf(" format name: %s\n", avfc->iformat->name);
    printf("   long name: %s\n", avfc->iformat->long_name);
    printf("  extensions: %s\n", avfc->iformat->extensions);
    printf("   mime type: %s\n", avfc->iformat->mime_type);
    puts("-------------");
#endif
    
    avformat_close_input(&avfc);
    return self;
}

- (AVFormatContext *)createAVFormatWithURL:(NSURL *)url {
    
    AVFormatContext *avfc = NULL;
    const char *cUrl = NULL;
    
    if (url.fileURL) {
        cUrl = url.fileSystemRepresentation;
    } else {
        cUrl = url.absoluteString.UTF8String;
    }
    
    int e = avformat_open_input(&avfc, cUrl, /*format*/ nil, /*options*/ nil);
    
    AVFormatContext*(^didFail)() = ^{
        self->_status = MPVPlayerItemStatusFailed;
        self->_error = [NSError errorWithDomain:MPVPlayerItemErrorDomain code:e
                            userInfo:@{ NSURLErrorKey: url,
                            NSLocalizedDescriptionKey: @(av_err2str(e)) }];
        if (avfc) {
            avformat_close_input((AVFormatContext**)(&avfc));
        }
        return (AVFormatContext*)(NULL);
    };
    
    if (e) {
        return didFail();
    }
    
    e = avformat_find_stream_info(avfc, /*options*/ nil);
    if (e) {
        return didFail();
    }
    
    return avfc;
}

- (void)readStreams:(AVFormatContext *)avfc {
    NSMutableArray *result = [NSMutableArray new];
    
    for (typeof(avfc->nb_streams) i = 0; i < avfc->nb_streams; i++) {
        MPVPlayerItemTrack *track = [[MPVPlayerItemTrack alloc]
                                   initWithFormat:avfc stream:avfc->streams[i]];
        [result addObject:track];
        
        switch (avfc->streams[i]->codecpar->codec_type) {
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
    
    id (^findBestStream)(AVFormatContext*, enum AVMediaType, NSArray*) =
    ^(AVFormatContext *ctx, enum AVMediaType type, NSArray *streams) {
        int idx = av_find_best_stream(ctx, type, /*wanted_stream*/ -1,
                     /*related_stream*/ -1, /*decoder_ret*/ NULL, /*flags*/ 0);
        if (idx >= 0) {
            return streams[idx];
        }
        return (id)nil;
    };
    
    if (_hasVideoStreams) {
        _bestVideoTrack = findBestStream(avfc, AVMEDIA_TYPE_VIDEO, result);
    }
    
    if (_hasAudioStreams) {
        _bestAudioTrack = findBestStream(avfc, AVMEDIA_TYPE_AUDIO, result);
    }
    _tracks = result;
}

- (void)readMetadata:(AVFormatContext *)avfc {
    AVDictionaryEntry *pair = NULL;
    NSMutableArray *result = [NSMutableArray new];
    
    while ((pair = av_dict_get(avfc->metadata, /*key*/"", pair,
                               AV_DICT_IGNORE_SUFFIX)))
    {
        [result addObject:[[MPVMetadataItem alloc]
                         initWithIdentifier:@(pair->key) value:@(pair->value)]];
    }
    
    _metadata = result;
}

#pragma mark - Properties

- (NSString *)filePath {
    return _url.path;
}

@end
