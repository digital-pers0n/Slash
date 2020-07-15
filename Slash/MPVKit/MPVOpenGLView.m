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
#import "MPVLock.h"
#import "MPVKitDefines.h"
#import "MPVGLRenderer.h"

#import <OpenGL/gl.h>
#import <OpenGL/gl3.h>

@interface MPVOpenGLView () {
    NSOpenGLContext *_glContext;
    dispatch_queue_t _render_queue;
    MPVGLRenderer _mpv;
}

- (NSError *)setUpWithFrame:(NSRect)frame OBJC_DIRECT;

@end

OBJC_DIRECT_MEMBERS
@interface MPVOpenGLView (MPVGLRenderer)

- (NSError *)createMPVRenderer;
- (void)destroyMPVRenderer;
- (void)useDefaultRenderCallback;
- (void)useResizeRenderCallback;

@end

OBJC_DIRECT_MEMBERS
@interface MPVOpenGLView (Errors)

- (NSError *)errorWithCode:(int)code description:(NSString *)description
                suggestion:(NSString *)suggestion;

@end

@implementation MPVOpenGLView

#pragma mark - Initialization

- (nullable instancetype)initWithFrame:(NSRect)frame
                                player:(nullable MPVPlayer *)player
                                 error:(out NSError **)error
{
    NSOpenGLPixelFormat *pf = [self openGLPixelFormatWithError:error];
    if (!pf) {
        return nil;
    }
    self = [super initWithFrame:frame pixelFormat:pf];
    if (self) {
        if (!player) {
            _player = [[MPVPlayer alloc] init];
            if (_player.status == MPVPlayerStatusFailed) {
                *error = _player.error;
                return nil;
            }
        } else {
            _player = player;
        }
        NSError *err = [self setUpWithFrame:frame];
        if (err) {
            *error = err;
            return nil;
        }
    } else {
        *error = [self errorWithCode:-1
                         description:@"Cannot initialize OpenGL View."
                          suggestion:@"-initWithFrame:pixelFormat: returned nil"];
    }
    return self;
}

- (instancetype)initWithPlayer:(MPVPlayer *)player {
    NSError *error = nil;
    self = [self initWithFrame:NSMakeRect(0, 0, 640, 480)
                        player:player error:&error];
    if (error) {
        NSLog(@"Error: %@", error);
        return nil;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    NSError *error = nil;
    self = [self initWithFrame:frame player:nil error:&error];
    if (error) {
        NSLog(@"Error: %@", error);
        return nil;
    }
    return self;
}

- (NSError *)setUpWithFrame:(NSRect)frame {

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(playerWillShutdown:)
               name:MPVPlayerWillShutdownNotification
             object:_player];
    
    dispatch_queue_attr_t attr;
    attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL,
                                                   QOS_CLASS_USER_INTERACTIVE, 0);
    _render_queue = dispatch_queue_create("com.home.MPVOpenGLView.render-queue",
                                          attr);

    _glContext = self.openGLContext;
    
    NSError * error = [self createMPVRenderer];
    if (error) {
        return error;
    }

    mpvgl_set_size(&_mpv, NSWidth(frame), NSHeight(frame));
    
    GLint swapInt = 1;
    [_glContext setValues:&swapInt
             forParameter:NSOpenGLContextParameterSwapInterval];
    
    return nil;
}

- (CGLError)chooseCGLPixelFormat:(CGLPixelFormatObj *)pix {
    return mpvgl_choose_pixel_format(pix);
}

- (NSOpenGLPixelFormat *)openGLPixelFormatWithError:(out NSError **)error {
    CGLPixelFormatObj pix = nil;
    CGLError result = [self chooseCGLPixelFormat:&pix];
    if (result != kCGLNoError) {
        *error = [self errorWithCode:result
                         description:@"Cannot create OpenGL pixel format."
                          suggestion:@(CGLErrorString(result))];
        return nil;
    }
    id pf = [[NSOpenGLPixelFormat alloc] initWithCGLPixelFormatObj:pix];
    CGLReleasePixelFormat(pix);
    return pf;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self destroyMPVRenderer];
}

- (void)destroyRenderContext {
    [self destroyMPVRenderer];
}

#pragma mark - Overrides

- (void)reshape {
    if (!self.inLiveResize) {
        typeof(_mpv) *mpv = &_mpv;
        NSSize size = [self convertSizeToBacking:self.frame.size];
        mpvgl_lock(mpv);
        mpvgl_set_size(mpv, size.width, size.height);
        [super reshape];
        mpvgl_unlock(mpv);
    }
}

- (void)update {
    typeof(_mpv) *mpv = &_mpv;
    mpvgl_lock(mpv);
    [super update];
    mpvgl_unlock(mpv);
}

- (void)viewWillStartLiveResize {
    if (mpvgl_is_valid(&_mpv)) {
        self.canDrawConcurrently = YES;
        [self useResizeRenderCallback];
    }
}

- (void)viewDidEndLiveResize {
    if (mpvgl_is_valid(&_mpv)) {
        self.canDrawConcurrently = NO;
        [self reshape];
        [self update];
        [self useDefaultRenderCallback];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    if (mpvgl_is_valid(&_mpv)) {
        if (self.inLiveResize) {
            typeof(_mpv) *mpv = &_mpv;
            NSSize size = [self convertSizeToBacking:self.frame.size];
            mpvgl_lock(mpv);
            mpvgl_set_size(mpv, size.width, size.height);
            resize(&_mpv);
            mpvgl_unlock(mpv);
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
        if (mpvgl_is_valid(&_mpv)) {
            [self useDefaultRenderCallback];
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
    [self destroyMPVRenderer];
}

#pragma mark - mpv_render_context callbacks

static void render_frame(void *ctx) {
    MPVGLRenderer *mpv = ctx;
    mpvgl_make_current(mpv);
    mpvgl_render(mpv);
    mpvgl_flush(mpv);
}

static void render_context_callback(void *ctx) {
    __unsafe_unretained MPVOpenGLView *obj = (__bridge id)ctx;
    dispatch_async_f(obj->_render_queue, &obj->_mpv, &render_frame);
}

#pragma mark live resize

static void resize(void *ctx) {
    MPVGLRenderer *mpv = ctx;
    mpvgl_make_current(mpv);
    mpvgl_update(mpv);
    mpv_opengl_fbo fbo = mpv->fbo;
    int flag = 1;
    int block_time = 0;
    mpv_render_param params[] = {
        { .type = MPV_RENDER_PARAM_OPENGL_FBO, .data = &fbo },
        { .type = MPV_RENDER_PARAM_FLIP_Y,     .data = &flag },
        { .type = MPV_RENDER_PARAM_BLOCK_FOR_TARGET_TIME, .data = &block_time },
        { 0 } };
    mpvgl_render(mpv, params);
    mpvgl_flush(mpv);
}

static void live_resize(void *ctx) {
    MPVGLRenderer *mpv = ctx;
    mpvgl_lock(mpv);
    if (mpvgl_has_frame(mpv)) {
        resize(mpv);
    }
    mpvgl_unlock(mpv);
}

static void render_live_resize_callback(void *ctx) {
    __unsafe_unretained MPVOpenGLView *obj = (__bridge id)ctx;
    dispatch_async_f(obj->_render_queue, &obj->_mpv, (void *)live_resize);
}

@end

@implementation MPVOpenGLView (MPVGLRenderer)

- (NSError *)createMPVRenderer {
    CGLContextObj cgl = _glContext.CGLContextObj;
    int result = mpvgl_init(&_mpv, _player.mpv_handle, cgl, false);
    if (result != MPV_ERROR_SUCCESS) {
        if (result == MPVGL_ERROR_OPENGL_FRAMEWORK_UNAVAILABLE) {
            NSString *desc = @"Cannot load OpenGL.framework";
            NSString *info = nil;
            const char *tmp = dlerror();
            info = [NSString stringWithFormat:@"Error while loading '%s'. %s",
                    MPVGL_OPENGL_FRAMEWORK_PATH, tmp ? tmp : ""];
            return [self errorWithCode:result description:desc suggestion:info];
        }
        return [self errorWithCode:result
                       description:@"Cannot create mpv render context."
                        suggestion:@(mpv_error_string(result))];
    }
    static int flip_y = 1;
    mpv_render_param param = { .type = MPV_RENDER_PARAM_FLIP_Y, .data = &flip_y };
    mpvgl_set_aux_parameter(&_mpv, param);
    
    return nil;
}

- (void)destroyMPVRenderer {
    [_glContext clearDrawable];
    mpvgl_destroy(&_mpv);
}

- (void)useDefaultRenderCallback {
    mpvgl_set_update_callback(&_mpv, &render_context_callback,
                              (__bridge void *)self);
}

- (void)useResizeRenderCallback {
    mpvgl_set_update_callback(&_mpv, &render_live_resize_callback,
                              (__bridge void *)self);
}

@end

@implementation MPVOpenGLView (Errors)

- (NSError *)errorWithCode:(int)code description:(NSString *)description
                suggestion:(NSString *)suggestion
{
    id info = @{ NSLocalizedDescriptionKey             : description,
                 NSLocalizedRecoverySuggestionErrorKey : suggestion };
    return [NSError errorWithDomain:MPVPlayerErrorDomain code:code userInfo:info];
}

@end
