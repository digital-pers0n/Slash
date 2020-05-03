//
//  MPVOpenGLView.m
//  Slash
//
//  Created by Terminator on 2019/10/14.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "MPVOpenGLView.h"
#import "MPVPlayer.h"
#import <mpv/render_gl.h>
#import <dlfcn.h>
#import <pthread/pthread.h>
#import <pthread/pthread_spis.h>

#import <OpenGL/gl.h>
#import <OpenGL/gl3.h>

#define ENABLE_DOUBLE_BUFFER_PIXEL_FORMAT 1

static void *g_opengl_framework_handle;

static void * load_library(const char *path) {
    return dlopen(path, RTLD_LAZY | RTLD_LOCAL);
}

typedef struct mpv_data_ {
    mpv_render_context      *render_context;
    CGLContextObj           cgl_context;
    mpv_opengl_fbo          opengl_fbo;
    mpv_render_param        render_params[3];
    pthread_mutex_t         gl_lock;
} mpv_data;

@interface MPVOpenGLView () {
    NSOpenGLContext *_glContext;
    dispatch_queue_t _render_queue;
    dispatch_queue_t _main_queue;
    mpv_data _mpv;
}

@end

@implementation MPVOpenGLView

#pragma mark - Initialization

- (instancetype)initWithPlayer:(MPVPlayer *)player {
    
    NSOpenGLPixelFormat *pf = [self createOpenGLPixelFormat];
    if (!pf) {
        NSLog(@"Failed to create NSOpenGLPixelFormat object.");
        return nil;
    }
    
    self = [super initWithFrame:NSMakeRect(0, 0, 640, 480) pixelFormat:pf];
    if (self) {
        if (!player) {
            if ([self createMPVPlayer] != 0) {
                NSLog(@"Failed to create MPVPlayer object. -> %@", _player.error.localizedDescription);
                return nil;
            }
        } else {
            _player = player;
        }
        [self setUp];
    }
    
    return self;

}

- (instancetype)initWithFrame:(CGRect)frame
{
    NSOpenGLPixelFormat *pf = [self createOpenGLPixelFormat];
    if (!pf) {
        NSLog(@"Failed to create NSOpenGLPixelFormat object.");
        return nil;
    }
    
    self = [super initWithFrame:frame pixelFormat:pf];
    if (self) {
        if ([self createMPVPlayer] != 0) {
            NSLog(@"Failed to create MPVPlayer object. -> %@", _player.error.localizedDescription);
            return nil;
        }
        [self setUp];
    }
    
    return self;
}

- (void)setUp {
    
    pthread_mutexattr_t mattr;
    pthread_mutexattr_init(&mattr);
    pthread_mutexattr_setpolicy_np(&mattr, _PTHREAD_MUTEX_POLICY_FIRSTFIT);
    pthread_mutex_init(&_mpv.gl_lock, &mattr);
    pthread_mutexattr_destroy(&mattr);
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(playerWillShutdown:)
               name:MPVPlayerWillShutdownNotification
             object:_player];
    
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(
                                                                         DISPATCH_QUEUE_SERIAL,
                                                                         QOS_CLASS_USER_INTERACTIVE, 0);
    _render_queue = dispatch_queue_create("com.home.MPVOpenGLView.render-queue", attr);

    _main_queue = dispatch_get_main_queue();
    _glContext = self.openGLContext;
    _mpv.cgl_context = _glContext.CGLContextObj;
    
    NSRect frame = self.bounds;
    _mpv.opengl_fbo = (mpv_opengl_fbo) { .fbo = 0, .w = NSWidth(frame), .h = NSHeight(frame) };
    
    GLint swapInt = 1;
    [_glContext setValues:&swapInt
             forParameter:NSOpenGLContextParameterSwapInterval];
}

- (NSOpenGLPixelFormat *)createOpenGLPixelFormat {
    NSOpenGLPixelFormatAttribute attributes[] = {
        NSOpenGLPFANoRecovery,
        NSOpenGLPFAAllowOfflineRenderers,
        NSOpenGLPFAAccelerated,
        
#ifdef ENABLE_DOUBLE_BUFFER_PIXEL_FORMAT
        
        NSOpenGLPFADoubleBuffer,
        
#endif
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
        0
    };
    
    return [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
}

- (int)createMPVPlayer {
    _player = MPVPlayer.new;
    if (_player.status == MPVPlayerStatusFailed) {
        return -1;
    }
    return 0;
}

- (int)createMPVRenderContext {

    static int mpv_flip_y = 1;
    
    _mpv.render_params[0] = (mpv_render_param) { .type = MPV_RENDER_PARAM_OPENGL_FBO, .data = &_mpv.opengl_fbo };
    _mpv.render_params[1] = (mpv_render_param) { .type = MPV_RENDER_PARAM_FLIP_Y,     .data = &mpv_flip_y };
    _mpv.render_params[2] = (mpv_render_param) { 0 };
    
    if (!g_opengl_framework_handle) {
        
        const char *opengl_framework_path = "/System/Library/Frameworks/OpenGL.framework/OpenGL";
        void *handle = load_library(opengl_framework_path);
        if (!handle) {
            
            NSAlert *alert = [NSAlert new];
            alert.alertStyle = NSAlertStyleCritical;
            alert.messageText = @"Failed to load OpenGL.framework";
            const char *err = dlerror();
            alert.informativeText = [NSString stringWithFormat:@"Error while opening '%s'\n%s", opengl_framework_path, (err) ? err : ""];
            [alert runModal];
            return -1;
        }
        
        g_opengl_framework_handle = handle;
    }
    
    mpv_opengl_init_params mpv_opengl_init_params = {
        .get_proc_address = &dlsym,
        .get_proc_address_ctx = g_opengl_framework_handle
    };
    
    mpv_render_param params[] = {
        { .type = MPV_RENDER_PARAM_API_TYPE,           .data = MPV_RENDER_API_TYPE_OPENGL },
        { .type = MPV_RENDER_PARAM_OPENGL_INIT_PARAMS, .data = &mpv_opengl_init_params },
        { 0 }
    };
    
    [_glContext makeCurrentContext];
    
    return mpv_render_context_create(&_mpv.render_context, _player.mpv_handle, params);
}

- (void)destroyMPVRenderContext {
    [_glContext clearDrawable];
    mpv_render_context_set_update_callback(_mpv.render_context, NULL, NULL);
    mpv_render_context_free(_mpv.render_context);
    _mpv.render_context = NULL;
    pthread_mutex_destroy(&_mpv.gl_lock);
}

- (void)dealloc {
    if (_mpv.render_context) {
        [self destroyMPVRenderContext];
    }
}


#pragma mark - Overrides

- (void)reshape {
    
    if (!self.inLiveResize) {
        
        pthread_mutex_lock(&_mpv.gl_lock);
        NSSize  surfaceSize = [self convertRectToBacking:self.bounds].size;
        _mpv.opengl_fbo.w = surfaceSize.width;
        _mpv.opengl_fbo.h = surfaceSize.height;
        
#ifdef MAC_OS_X_VERSION_10_14
        
        [super reshape];
        
#endif
        
        pthread_mutex_unlock(&_mpv.gl_lock);
    }
    
#ifdef MAC_OS_X_VERSION_10_14
    else {
        pthread_mutex_lock(&_mpv.gl_lock);
        
        [super reshape];
        
        pthread_mutex_unlock(&_mpv.gl_lock);
    }
#endif
    
}

- (void)update {
    
#ifdef MAC_OS_X_VERSION_10_14
    
    pthread_mutex_lock(&_mpv.gl_lock);
    
    [super update];
    
    pthread_mutex_unlock(&_mpv.gl_lock);
    
#else
    [_glContext update];
#endif
    
}

- (void)viewWillStartLiveResize {
    
    if (_mpv.render_context) {

        self.canDrawConcurrently = YES;
        mpv_render_context_set_update_callback(_mpv.render_context, &render_live_resize_callback, (__bridge void *)self );
    }
}

- (void)viewDidEndLiveResize {
    
    if (_mpv.render_context) {
        self.canDrawConcurrently = NO;
        
        [self reshape];
        [self update];
        
        mpv_render_context_set_update_callback(_mpv.render_context, &render_context_callback, (__bridge void *)self );
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    
    if (_mpv.render_context) {
        if (self.inLiveResize) {
            pthread_mutex_lock(&_mpv.gl_lock);
            
            NSSize  surfaceSize = [self convertRectToBacking:self.bounds].size;
            _mpv.opengl_fbo.w = surfaceSize.width;
            _mpv.opengl_fbo.h = surfaceSize.height;
            resize(&_mpv);
            
            pthread_mutex_unlock(&_mpv.gl_lock);

        } else {
            if ([_player isPaused]) { // force redraw
               dispatch_async_f(_render_queue, &_mpv, &render_frame);
            }
        }
    } else {
        fillBlack(self.bounds);
    }
}

static void fillBlack(NSRect rect) {
    [[NSColor blackColor] set];
    NSRectFill(rect);
}

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    if (self.window) {
        if (!_mpv.render_context) {
            int error;
            if ((error = [self createMPVRenderContext]) != MPV_ERROR_SUCCESS) {
                NSLog(@"Failed to create mpv_render_context. -> %s", mpv_error_string(error));
                return;
            }
            mpv_render_context_set_update_callback(_mpv.render_context, &render_context_callback, (__bridge void *)self );
        }
    }
}

- (BOOL)isOpaque {
    return YES;
}

- (BOOL)mouseDownCanMoveWindow {
    return YES;
}

#pragma mark - Notifications

- (void)playerWillShutdown:(NSNotification *)n {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_mpv.render_context) {
        [self destroyMPVRenderContext];
    }
}

#pragma mark - mpv_render_context callbacks

static void render_frame(void *ctx) {
    mpv_data *obj = ctx;
    CGLSetCurrentContext(obj->cgl_context);
    mpv_render_context_render(obj->render_context, obj->render_params);
    
#ifdef ENABLE_DOUBLE_BUFFER_PIXEL_FORMAT
    CGLFlushDrawable(obj->cgl_context);
#else
    glFlush();
#endif
    
}

static void render_context_callback(void *ctx) {
    __unsafe_unretained MPVOpenGLView *obj = (__bridge id)ctx;
    dispatch_async_f(obj->_render_queue, &obj->_mpv, &render_frame);
}

#pragma mark live resize

static void resize(void *ctx) {
    mpv_data *obj = ctx;
    {
        CGLSetCurrentContext(obj->cgl_context);
        CGLUpdateContext(obj->cgl_context);
        mpv_opengl_fbo fbo = obj->opengl_fbo;
        int flag = 1;
        int block_time = 0;
        mpv_render_param params[] = {
            { .type = MPV_RENDER_PARAM_OPENGL_FBO, .data = &fbo },
            { .type = MPV_RENDER_PARAM_FLIP_Y,     .data = &flag },
            { .type = MPV_RENDER_PARAM_BLOCK_FOR_TARGET_TIME, .data = &block_time },
            { 0 } };
        
        mpv_render_context_render(obj->render_context, params);
        
#ifdef ENABLE_DOUBLE_BUFFER_PIXEL_FORMAT
        CGLFlushDrawable(obj->cgl_context);
#else
        glFlush();
#endif
        
    }
}

static void live_resize(void *ctx) {
    mpv_data *mpv = ctx;
    pthread_mutex_lock(&mpv->gl_lock);
    
    if (mpv_render_context_update(mpv->render_context) & MPV_RENDER_UPDATE_FRAME) {
        resize(mpv);
    }
    
    pthread_mutex_unlock(&mpv->gl_lock);
}

static void render_live_resize_callback(void *ctx) {
    __unsafe_unretained MPVOpenGLView *obj = (__bridge id)ctx;
    dispatch_async_f(obj->_render_queue, &obj->_mpv, (void *)live_resize);
}

@end
