//
//  MPVPlayerItemTrack.m
//  Slash
//
//  Created by Terminator on 2019/10/21.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "MPVPlayerItemTrack.h"
#import "MPVMetadataItem.h"
#import "MPVKitDefines.h"
#import <libavformat/avformat.h>
#import <libavcodec/avcodec.h>
#import <libavutil/pixdesc.h>
#import <libavutil/bprint.h>

OBJC_DIRECT_MEMBERS
@implementation MPVPlayerItemTrack

/* Based on the show_stream() function from the ffprobe.c */
- (instancetype)initWithFormat:(void *)formatData stream:(void *)streamData {
    self = [super init];
    if (self) {
        AVFormatContext *format = formatData;
        AVStream *stream = streamData;
        AVCodecParameters *params = stream->codecpar;

        const char * string = nil;
        
        _trackIndex = stream->index;
        _bitRate = params->bit_rate;
        
        _startTime = convert_to_seconds(stream->start_time, &stream->time_base);
        _duration = convert_to_seconds(stream->duration, &stream->time_base);
        
        _channelLayout = @"";
        _sampleFormatName = @"";
        _pixFormatName = @"";
        _fieldOrder = @"";
        
        [self readMetadata:stream->metadata];
        
        switch (params->codec_type) {
            
            case AVMEDIA_TYPE_VIDEO:
            {
                _mediaType = MPVMediaTypeVideo;
                _videoSize = NSMakeSize(params->width, params->height);
                _codedVideoSize = NSMakeSize(stream->codec->coded_width, stream->codec->coded_height);
                
                AVRational sar = av_guess_sample_aspect_ratio(format, stream, nil);
                if (sar.num) {
                    _sampleAspectRatio = NSMakeSize(sar.num, sar.den);
                    AVRational dar;
                    av_reduce(&dar.num, &dar.den, params->width * sar.num, params->height * sar.den, 1024*1024);
                    _displayAspectRatio = NSMakeSize(dar.num, dar.den);
                } else {
                    _displayAspectRatio = _sampleAspectRatio = NSZeroSize;
                }
            
                
                if (stream->avg_frame_rate.den) {
                    _averageFrameRate = av_q2d(stream->avg_frame_rate);
                }
                
                if (stream->r_frame_rate.den) {
                    _realBaseFrameRate = av_q2d(stream->r_frame_rate);
                }
                
                string =  av_get_pix_fmt_name(params->format);
                _pixFormatName = cstr2nsstr(string);
                
                _numberOfFrames = stream->nb_frames;
                _level = params->level;
                
                switch (params->field_order) {
                    
                    case AV_FIELD_PROGRESSIVE:
                        _fieldOrder = @"progressive";
                        break;
                        
                    case AV_FIELD_TT:
                        _fieldOrder = @"tt";
                         _interlaced = YES;
                        break;
                        
                    case AV_FIELD_BB:
                        _fieldOrder = @"bb";
                         _interlaced = YES;
                        break;
                        
                    case AV_FIELD_TB:
                        _fieldOrder = @"tb";
                         _interlaced = YES;
                        break;
                        
                    case AV_FIELD_BT:
                        _fieldOrder = @"bt";
                         _interlaced = YES;
                        break;
                        
                    default:
                        _fieldOrder = @"unknown";
                        break;
                }
                
            }
                break;
            
            case AVMEDIA_TYPE_AUDIO: {
                _mediaType = MPVMediaTypeAudio;
                _sampleRate = params->sample_rate;
                _numberOfChannels = params->channels;
                
                if (params->channel_layout) {
                    AVBPrint print_buf;
                    av_bprint_init(&print_buf, 1, AV_BPRINT_SIZE_UNLIMITED);
                    av_bprint_channel_layout(&print_buf, params->channels, params->channel_layout);
                    _channelLayout = cstr2nsstr(print_buf.str);
                    av_bprint_finalize(&print_buf, nil);
                }
                
                string = av_get_sample_fmt_name(params->format);
                _sampleFormatName = @(string);
                
            }
                break;
            case AVMEDIA_TYPE_SUBTITLE:
                _mediaType = MPVMediaTypeText;
                _videoSize = NSMakeSize(params->width, params->height);
                break;
                
            case AVMEDIA_TYPE_DATA:
                _mediaType = MPVMediaTypeData;
                break;
                
            case AVMEDIA_TYPE_ATTACHMENT:
                _mediaType = MPVMediaTypeAttachment;
                break;
                
            default:
                _mediaType = MPVMediaTypeUnknown;
                break;
        }
        
        string = av_get_media_type_string(params->codec_type);
        _mediaTypeName = cstr2nsstr(string);
        
        const AVCodecDescriptor *desc = avcodec_descriptor_get(params->codec_id);
        if (desc) {
            _codecName = cstr2nsstr(desc->name);
            _codecLongName = cstr2nsstr(desc->long_name);
        } else {
            _codecName = @"unknown";
            _codecLongName = @"unknown";
        }
        
        string = avcodec_profile_name(params->codec_id, params->profile);
        _profileName = cstr2nsstr(string);

    }
    return self;
}

- (void)readMetadata:(AVDictionary *)metadata {
    AVDictionaryEntry *pair = nil;
    NSMutableArray *result = [NSMutableArray new];
    
    while ((pair = av_dict_get(metadata, "", pair, AV_DICT_IGNORE_SUFFIX))) {
        [result addObject:[[MPVMetadataItem alloc] initWithIdentifier:@(pair->key) value:@(pair->value)]];
    }
    
    NSString *lang = nil;
    if (result.count) {
        NSMutableDictionary *dict = [NSMutableDictionary new];
        for (MPVMetadataItem *item in result) {
            dict[item.identifier.lowercaseString] = item.value;
        }
        lang = dict[@"language"];
    }
    
    _language = (lang) ? lang : @"und";
    
    _metadata = result;
}

static NSString * cstr2nsstr(const char *str) {
    return (str) ? @(str) : @"";
}

static double convert_to_seconds(int64_t ts, AVRational *time_base) {
    if (ts == AV_NOPTS_VALUE || ts == 0 || time_base->den == 0) {
        return 0;
    }
    return ts * av_q2d(*time_base);
}

@end

