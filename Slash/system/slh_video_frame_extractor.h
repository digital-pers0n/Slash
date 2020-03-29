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
        Release the @c outImage with @c CFRelease() after you don't
        need it anymore. Must not be NULL.
 
 @return 0 on success or -1 on error. If an error occurs @c outImage is left uncahnged.

 */
int vfe_get_image(const char * const ffmpegPath,
                  double seconds,
                  CGSize vSize,
                  const char * const filePath,
                  CGImageRef * outImage);

/**
 @param ctx User-defined context.
 @param ts Estimated timestamp of the current keyframe in seconds.
 @param image Output image, pass it to @c CFRelease() or @c CGImageRelease()
        after you don't need it anymore.
 */
typedef void (*vfe_callback_f)(void *ctx, double ts, CGImageRef image);

/**
 Extract keyframes from a video file and convert them into CGImages.
 
 @discussion The funciton divides the duration of the video file into intervals. 
 The number of intervals is equal to the @c nFrames parameter. Then from each 
 interval one keyframe is extracted. If there are no keyframes inside the 
 interval than it is discarded.
 
 @param filePath Full path to a video file. Must not be NULL.
 @param nFrames Number of keyframes to decode. If the video file doesn't contain
                enough keyframes then total number will be less than @c nFrames.
                This parameter must be greater than zero.
 @param vSize Size for downscaling or upscaling an output image.
 @param ctx Pointer to a user-defined context.
 @param callback Pointer to a user-defined funciton. Called for each frame 
                 index. The total number of calls is determinded by
                 the @c nFrames parameter and might be lower if there aren't 
                 enough keyframes in the video file. 
                 This parameter must not be NULL.

 @return 0 on success or non-zero if an error occurs.
 */
int vfe_get_keyframes(const char * const filePath,
                      size_t nFrames,
                      CGSize vSize,
                      void * ctx,
                      vfe_callback_f callback);


#endif /* slh_video_frame_extractor_h */
