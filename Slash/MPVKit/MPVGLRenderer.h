//
//  MPVGLRenderer.h
//  Slash
//
//  Created by Terminator on 2020/06/11.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#ifndef MPVGLRenderer_h
#define MPVGLRenderer_h

#if MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_13
#define GL_SILENCE_DEPRECATION 1
#endif

#include <OpenGL/OpenGL.h>
#include <errno.h>
#include <mpv/render_gl.h>

#include "MPVLock.h"

#define MPVGL_ERROR_OPENGL_FRAMEWORK_UNAVAILABLE ELAST+1

#ifndef USE_MPVLOCK
#define USE_MPVLOCK 1
#endif

#ifndef USE_DOUBLE_BUFFER_PIXEL_FORMAT
#define USE_DOUBLE_BUFFER_PIXEL_FORMAT 1
#endif

#define MPVGL_OPENGL_FRAMEWORK_PATH "/System/Library/Frameworks" \
                                    "/OpenGL.framework/OpenGL"

typedef struct MPVGLRenderer_ {
    mpv_render_context      *ctx;
    CGLContextObj           cgl;
    mpv_opengl_fbo          fbo;
    mpv_render_param        params[3];
#if USE_MPVLOCK
    MPVLock                 lock;
#endif
} MPVGLRenderer;

/**
 Initialize a MPVGLRenderer context.
 
 @param mpvgl Pointer to MPVGLRenderer structure. Must not be NULL.
 @param handle Pointer to initialized mpv_handle structure. Must not be NULL.
 @param cgl Initialized CGL context. Must not be NULL.
 @param enable_advanced_control Enable @c MPV_RENDER_PARAM_ADVANCED_CONTROL.
 
 @return 0 on success. @c MPVGL_ERROR_OPENGL_FRAMEWORK_UNAVAILABLE if OpenGL
         framework cannot be opened or one of MPV_ERROR_* values returned by the
         @c mpv_render_context_create() function.
 */
int mpvgl_init(MPVGLRenderer *mpvgl, mpv_handle *handle,
               CGLContextObj cgl, bool enable_advanced_control);


/**
 Destroy the MPVGLRenderer context.
 
 @param mpvgl Previously initialized context. Must not be NULL.
 */
void mpvgl_destroy(MPVGLRenderer *mpvgl);

/**
 Set an auxiliary render parameter.
 */
void mpvgl_set_aux_parameter(MPVGLRenderer *mpvgl, mpv_render_param parameter);

/**
 Set the size of the mpv render context.
 */
void mpvgl_set_size(MPVGLRenderer *mpvgl, int w, int h);

/**
 Set the mpv render update callback.
 */
void mpvgl_set_update_callback(MPVGLRenderer *mpvgl,
                               mpv_render_update_fn cb, void *user_context);

/**
 Reset the mpv render update callback to NULL.
 */
void mpvgl_reset_update_callback(MPVGLRenderer *mpvgl);

/**
 Render the current frame with user-defined parameters.
 
 @param params Must not be NULL.
 */
void mpvgl_render(MPVGLRenderer *mpvgl, mpv_render_param *params);

/**
 Render the current frame with default parameters.
 */
__attribute__((overloadable))
static inline void mpvgl_render(MPVGLRenderer *mpvgl) {
    mpvgl_render(mpvgl, mpvgl->params);
}

/**
 Lock the renderer context.
 */
void mpvgl_lock(MPVGLRenderer *mpvgl);

/**
 Unlock the renderer context.
 */
void mpvgl_unlock(MPVGLRenderer *mpvgl);

/**
 Make the CGL context current.
 */
void mpvgl_make_current(MPVGLRenderer *mpvgl);

/**
 Update the CGL context.
 */
void mpvgl_update(MPVGLRenderer *mpvgl);

/**
 Flush the CGL context.
 */
void mpvgl_flush(MPVGLRenderer *mpvgl);

/**
 Lock the renderer context and make the CGL context current.
 Calls must be balanced with @c mpvgl_frame_end() calls after.
 */
void mpvgl_frame_begin(MPVGLRenderer *mpvgl);

/**
 Flush the CGL context, and unlock the renderer context.
 Must be only called after @c mpvgl_frame_begin() call.
 */
void mpvgl_frame_end(MPVGLRenderer *mpvgl);

/**
 Check if a frame available to be rendered.
 */
bool mpvgl_has_frame(MPVGLRenderer *mpvgl);

/**
 Check if the renderer context is valid
 */
bool mpvgl_is_valid(MPVGLRenderer *mpvgl);

#endif /* MPVGLRenderer_h */
