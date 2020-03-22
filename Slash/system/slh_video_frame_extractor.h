//
//  slh_video_frame_extractor.h
//  Slash
//
//  Created by Terminator on 2020/03/22.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#ifndef slh_video_frame_extractor_h
#define slh_video_frame_extractor_h

#include <stdio.h>
#include <CoreGraphics/CGImage.h>

/**
 
 Extract a single frame from a video file and convert it to a CGImageRef image.
 
 @param ffmpegPath a path to a ffmpeg executable. Must not be NULL.
 @param seconds indicate a postion where a video frame should be extracted.
 @param vSize size a desired size for upscaling or downscaling.
 @param filePath a path to a video file. Must not be NULL.
 @param outImage a pointer to CGImageRef to store exctracted image.
        Release the @c outImage with @c CFRelase() after you don't 
        need it anymore. Must not be NULL.
 
 @return 0 on success or -1 on error. If an error occurs @c outImage is left uncahnged.

 */
int vfe_get_image(const char * const ffmpegPath,
                  double seconds,
                  CGSize vSize,
                  const char * const filePath,
                  CGImageRef * outImage);

#endif /* slh_video_frame_extractor_h */
