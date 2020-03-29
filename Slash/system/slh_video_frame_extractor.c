//
//  slh_video_frame_extractor.c
//  Slash
//
//  Created by Terminator on 2020/03/22.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#include <ImageIO/CGImageSource.h>

#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include <libavutil/imgutils.h>

#include "slh_video_frame_extractor.h"
#include "slh_process.h"

int vfe_get_image(const char * const ffmpegPath,
                  double seconds,
                  CGSize vSize,
                  const char * const filePath,
                  CGImageRef * outImage)
{
    char sizeStr[16];
    snprintf(sizeStr, sizeof(sizeStr), "%.0fx%.0f", vSize.width, vSize.height);
    char timeStr[16];
    snprintf(timeStr, sizeof(timeStr), "%.3f", seconds);
    Process ffmpeg;
    
    const char *const args[] = {
        ffmpegPath,
        "-loglevel",    "0",
        "-ss",          timeStr,
        "-i",           filePath,
        "-s",           sizeStr,
        "-vframes",     "1",
        "-q:v",         "3",
        "-f",           "image2pipe",
        "-",            NULL
    };
    
    prc_init_no_copy(&ffmpeg, (char **)args);
    if (prc_launch(&ffmpeg) != 0) {
        prc_destroy_no_copy(&ffmpeg);
        fprintf(stderr, "%s Cannot extract preview image from '%s'\n",
              __PRETTY_FUNCTION__, filePath);
        return -1;
    }
    
    const size_t block_length = 4096;
    size_t bytes_total = 0;
    size_t bytes_read = 0;
    uint8_t *frame = malloc(block_length * sizeof(uint8_t));
    
    while ((bytes_read = fread(frame + bytes_total,
                               sizeof(uint8_t),
                               block_length,
                               prc_stdout(&ffmpeg))) > 0) {
        
        bytes_total += bytes_read;
        uint8_t *tmp = realloc(frame,
                               bytes_total * sizeof(uint8_t) + block_length);
        if (!tmp) {
            fprintf(stderr, "%s Fatal error %s\n",
                    __PRETTY_FUNCTION__, strerror(errno));
            prc_destroy_no_copy(&ffmpeg);
            free(frame);
            return -1;
        }
        frame = tmp;
    }
    
    CFDataRef cfData = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault,
                                                   frame,
                                                   bytes_total,
                                                   kCFAllocatorMalloc);
    
    CGImageSourceRef imageSource = CGImageSourceCreateWithData(cfData, nil);
    CGImageRef cgImage = CGImageSourceCreateImageAtIndex(imageSource,
                                                         0, nil);
    *outImage = cgImage;
    
    prc_destroy_no_copy(&ffmpeg);
    
    if (imageSource) {
        CFRelease(imageSource);
    }
    
    if (cfData) {
        CFRelease(cfData);
    } else if (frame) {
        free(frame);
    }
    
    return 0;
}

#pragma mark - Keyframes extractor

typedef struct VFEData_ {
    AVFormatContext     * fmtctx; ///< Input file format context
    AVStream            * stream; ///< Stream to decode
    AVCodecContext      * decctx; ///< Decoder context
    struct SwsContext   * swsctx; ///< Scaler to convert a video frame to an image
} VFEData;

static int vfe_init(VFEData * ffmpeg,
                    const char * const filePath,
                    CGSize vSize)
{
    int error = 0;
    
    AVFormatContext * fmtctx = NULL;

    if ((error = avformat_open_input(&fmtctx, filePath, NULL, NULL)) < 0) {
        fprintf(stderr, "%s: Cannot open input: %s\n",
                __func__, av_err2str(error));
        avformat_close_input(&fmtctx);
        return error;
    }
    
    if ((error = avformat_find_stream_info(fmtctx, NULL)) < 0) {
        fprintf(stderr, "%s: Cannot find stream info: %s\n",
                __func__, av_err2str(error));
        avformat_close_input(&fmtctx);
        return error;
    }
    
    AVCodec * dec = NULL;
    int videoStreamIdx = av_find_best_stream(fmtctx, AVMEDIA_TYPE_VIDEO,
                                             -1, -1, &dec, 0);
    if (videoStreamIdx < 0) {
        error = videoStreamIdx;
        fprintf(stderr, "%s: Cannot find video streams: %s\n",
                __func__, av_err2str(error));
        avformat_close_input(&fmtctx);
        return error;
    }
    
    AVStream * stream = fmtctx->streams[videoStreamIdx];
    AVRational fps = stream->avg_frame_rate;
    if (fps.den == 0 || fps.num == 0) {
        fprintf(stderr, "%s: Invalid frame rate\n", __func__);
        avformat_close_input(&fmtctx);
        error = -1;
        return error;
    }
    
    AVCodecContext * decctx = avcodec_alloc_context3(dec);
    avcodec_parameters_to_context(decctx, stream->codecpar);
    decctx->time_base = stream->time_base;
    
    if (decctx->pix_fmt < 0 || decctx->pix_fmt >= AV_PIX_FMT_NB) {
        error = -1;
        fprintf(stderr, "%s: Invalid pixel format\n", __func__);
        avcodec_free_context(&decctx);
        avformat_close_input(&fmtctx);
        return error;
    }
    
    if ((error = avcodec_open2(decctx, dec, NULL)) < 0) {
        fprintf(stderr, "%s: Cannot open codec: %s\n",
                __func__, av_err2str(error));
        avcodec_free_context(&decctx);
        avformat_close_input(&fmtctx);
        return error;
    }
    
    struct SwsContext * swsctx = sws_getContext(decctx->width, decctx->height,
                                                decctx->pix_fmt,
                                                vSize.width, vSize.height,
                                                AV_PIX_FMT_RGB24,
                                                SWS_FAST_BILINEAR,
                                                NULL, NULL, NULL);
    
    if (!swsctx) {
        fprintf(stderr, "%s: Cannot create sws context\n", __func__);
        avcodec_free_context(&decctx);
        avformat_close_input(&fmtctx);
        error = -1;
        return error;
    }
    
    ffmpeg->fmtctx = fmtctx;
    ffmpeg->stream = stream;
    ffmpeg->decctx = decctx;
    ffmpeg->swsctx = swsctx;

    return error;
}

static void vfe_destroy(VFEData * ffmpeg) {
    avcodec_free_context(&ffmpeg->decctx);
    sws_freeContext(ffmpeg->swsctx);
    avformat_close_input(&ffmpeg->fmtctx);
}

static inline int vfe_calculate_linesize(int width) {
    return ((3 * width + 15) / 16) * 16; // align for efficient swscale
}

static inline CGImageRef vfe_get_cgimage(uint8_t * inData,
                                         size_t inDataSize,
                                         size_t linesize,
                                         CGSize imageSize,
                                         CGColorSpaceRef colorSpace)
{
    CFDataRef imageData = CFDataCreate(NULL, inData, inDataSize);
    CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData(imageData);
    
    CGImageRef outImage = CGImageCreate(imageSize.width, imageSize.height,
                                        8, 24, linesize, colorSpace,
                                        kCGBitmapByteOrderDefault,
                                        dataProvider, NULL, false,
                                        kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    CFRelease(imageData);
    
    return outImage;
}

static int vfe_decode(VFEData * ffmpeg,
                      size_t nFrames,
                      CGSize vSize,
                      void * ctx,
                      vfe_callback_f cb)
{
    int error = 0;
    
    uint8_t * outRGBData = NULL;
    const int outLinesize = vfe_calculate_linesize((int)vSize.width);
    const size_t outDataSize = outLinesize * (int)vSize.height;
    if (!(outRGBData = malloc(outDataSize))) {
        fprintf(stderr, "%s: Cannot allocate data: %s\n",
                __func__, strerror(errno));
        error = -1;
        return error;
    }
    
    uint8_t * const dst[4] = { outRGBData };
    const int dstStride[4] = { outLinesize };
    
    AVFormatContext     * video     = ffmpeg->fmtctx;
    AVStream            * stream    = ffmpeg->stream;
    AVCodecContext      * decoder   = ffmpeg->decctx;
    struct SwsContext   * scaler    = ffmpeg->swsctx;

    AVFrame * frame = av_frame_alloc();
    const int64_t duration = av_rescale_q(video->duration,
                                          AV_TIME_BASE_Q,
                                          stream->time_base);
    const int64_t interval = duration / nFrames;
    double timebase = av_q2d(stream->time_base);

    AVPacket pkt;
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    const int videoStreamIdx = stream->index;
    const int64_t startTime = stream->start_time;
    int64_t previousTimestamp = INT64_MAX;
    
    for (size_t i = 0; i < nFrames; ++i) {
        int64_t seek = interval * i + startTime;
        avcodec_flush_buffers(decoder);

        if ((error = av_seek_frame(video, videoStreamIdx,
                                   seek, AVSEEK_FLAG_BACKWARD)) < 0)
        {
            fprintf(stderr, "%s: Cannot seek: %s\n",
                    __func__, av_err2str(error));
            goto done;
        }
        
        while (av_read_frame(video, &pkt) >= 0) {
            
            if (pkt.stream_index == videoStreamIdx) {
                if ((error = avcodec_send_packet(decoder, &pkt)) < 0) {
                    fprintf(stderr, "%s: Cannot send packet: %s\n",
                            __func__, av_err2str(error));
                    av_packet_unref(&pkt);
                    break;
                }
                
                if ((error = avcodec_receive_frame(decoder, frame)) < 0) {
                    av_packet_unref(&pkt);
                    if (error == AVERROR(EAGAIN)) {
                        continue;
                    } else {
                        fprintf(stderr, "%s: Cannot receive frame: %s\n",
                                __func__, av_err2str(error));
                        break;
                    }
                }
                
                if (previousTimestamp == frame->best_effort_timestamp) {
                    av_frame_unref(frame);
                    av_packet_unref(&pkt);
                    break; // discard duplicate
                }
                
                previousTimestamp = frame->best_effort_timestamp;
                
                sws_scale(scaler, (const uint8_t * const *)frame->data,
                          frame->linesize, 0, decoder->height, dst, dstStride);
                
                CGImageRef outImage = vfe_get_cgimage(outRGBData,
                                                      outDataSize,
                                                      outLinesize,
                                                      vSize, rgbColorSpace);
                cb(ctx, frame->best_effort_timestamp * timebase, outImage);

                av_frame_unref(frame);
                av_packet_unref(&pkt);
                break;
            }
            av_packet_unref(&pkt);
        }
    }

    av_packet_unref(&pkt);
    
done:
    
    CGColorSpaceRelease(rgbColorSpace);
    av_free(frame);
    free(outRGBData);

    return error;
}

int vfe_get_keyframes(const char * const filePath,
                      size_t nFrames,
                      CGSize vSize,
                      void * ctx,
                      vfe_callback_f cb)
{
    VFEData ffmpeg;
    int error = vfe_init(&ffmpeg, filePath, vSize);
    if (error < 0) {
        return error;
    }
    
    error = vfe_decode(&ffmpeg, nFrames, vSize, ctx, cb);
    vfe_destroy(&ffmpeg);
    
    return error;
}
