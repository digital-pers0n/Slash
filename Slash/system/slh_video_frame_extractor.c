//
//  slh_video_frame_extractor.c
//  Slash
//
//  Created by Terminator on 2020/03/22.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#include <ImageIO/CGImageSource.h>

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
    
    prc_init(&ffmpeg, (char **)args);
    if (prc_launch(&ffmpeg) != 0) {
        prc_destroy(&ffmpeg);
        fprintf(stderr, "%s Cannot extract preview image from '%s'",
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
            fprintf(stderr, "%s Fatal error %s",
                    __PRETTY_FUNCTION__, strerror(errno));
            prc_destroy(&ffmpeg);
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
    
    prc_destroy(&ffmpeg);
    
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
