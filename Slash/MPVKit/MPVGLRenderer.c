//
//  MPVGLRenderer.c
//  Slash
//
//  Created by Terminator on 2020/06/11.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#include "MPVGLRenderer.h"
#include <mpv/render.h>
#include <stdio.h>
#include <assert.h>
#include <dlfcn.h>
#include <OpenGL/gl.h>

static void *get_proc_address(void *ctx, const char *symbol) {
    return dlsym(ctx, symbol);
}

static const char k_opengl_framework_path[] = "/System/Library/Frameworks/"
                                              "OpenGL.framework/OpenGL";
static void *g_opengl_framework_handle;

static bool load_opengl_framework() {
    void *handle = dlopen(k_opengl_framework_path, RTLD_LAZY | RTLD_LOCAL);
    if (handle) {
        g_opengl_framework_handle = handle;
        return true;
    }
    return false;
}

int mpvgl_init(MPVGLRenderer *mpvgl, mpv_handle *mpv_handle,
               CGLContextObj cgl_context, bool advanced)
{
    assert(mpvgl);
    assert(mpv_handle);
    assert(cgl_context);
    
#if USE_MPVLOCK
    mpv_lock_init(&mpvgl->lock);
#endif
    
    //m->cgl = CGLRetainContext(cgl);
    
    mpvgl->params[0] = (mpv_render_param) {
        .type = MPV_RENDER_PARAM_OPENGL_FBO,
        .data = &mpvgl->fbo
    };
    
    mpvgl->params[1] = (mpv_render_param) { 0 };
    mpvgl->params[2] = (mpv_render_param) { 0 };
    
    if (!g_opengl_framework_handle) {
        if (!load_opengl_framework()) {
            return MPVGL_ERROR_OPENGL_FRAMEWORK_UNAVAILABLE;
        }
    }
    
    mpv_opengl_init_params init_params = {
        .get_proc_address = &get_proc_address,
        .get_proc_address_ctx = g_opengl_framework_handle
    };

    int flag = (advanced) ? 1 : 0;
    mpv_render_param params[] = {
        {
            .type = MPV_RENDER_PARAM_API_TYPE,
            .data = MPV_RENDER_API_TYPE_OPENGL
        },
        {
            .type = MPV_RENDER_PARAM_OPENGL_INIT_PARAMS,
            .data = &init_params
        },
        {
            .type = MPV_RENDER_PARAM_ADVANCED_CONTROL,
            .data = &flag
        },
        { 0 }
    };
    
    mpvgl_make_current(mpvgl);
    
    return mpv_render_context_create(&mpvgl->ctx, mpv_handle, params);
}

void mpvgl_destroy(MPVGLRenderer *m) {
    if (!m->ctx) { return; }
    mpvgl_reset_update_callback(m);
    CGLClearDrawable(m->cgl);
    mpv_render_context_free(m->ctx);
    m->ctx = NULL;
    //CGLReleaseContext(m->cgl);
    m->cgl = NULL;
    
#if USE_MPVLOCK
    mpv_lock_destroy(&m->lock);
#endif
    
}

inline void mpvgl_set_aux_parameter(MPVGLRenderer *m, mpv_render_param param) {
    m->params[1] = param;
}

inline void mpvgl_set_size(MPVGLRenderer *m, int w, int h) {
    m->fbo.w = w;
    m->fbo.h = h;
}

inline void mpvgl_set_update_callback(MPVGLRenderer *m,
                                      mpv_render_update_fn cb, void *ctx)
{
    mpv_render_context_set_update_callback(m->ctx, cb, ctx);
}

inline void mpvgl_reset_update_callback(MPVGLRenderer *m) {
    mpvgl_set_update_callback(m, NULL, NULL);
}

inline void mpvgl_render(MPVGLRenderer *m, mpv_render_param *params) {
    mpv_render_context_render(m->ctx, params);
}

inline void mpvgl_lock(MPVGLRenderer *m) {
#if USE_MPVLOCK
    mpv_lock_lock(&m->lock);
#else
    CGLLockContext(m->cgl);
#endif
}

inline void mpvgl_unlock(MPVGLRenderer *m) {
#if USE_MPVLOCK
    mpv_lock_unlock(&m->lock);
#else 
    CGLUnlockContext(m->cgl);
#endif
}

inline void mpvgl_make_current(MPVGLRenderer *m) {
    CGLSetCurrentContext(m->cgl);
}

inline void mpvgl_update(MPVGLRenderer *m) {
    CGLUpdateContext(m->cgl);
}

inline void mpvgl_flush(MPVGLRenderer *m) {
#if USE_DOUBLE_BUFFER_PIXEL_FORMAT
    CGLFlushDrawable(m->cgl);
#else 
    glFlush();
#endif
}

inline void mpvgl_frame_begin(MPVGLRenderer *m) {
    mpvgl_lock(m);
    mpvgl_make_current(m);
}

inline void mpvgl_frame_end(MPVGLRenderer *m) {
    mpvgl_flush(m);
    mpvgl_unlock(m);
}

inline bool mpvgl_has_frame(MPVGLRenderer *m) {
    if (mpv_render_context_update(m->ctx) & MPV_RENDER_UPDATE_FRAME) {
        return true;
    }
    return false;
}
