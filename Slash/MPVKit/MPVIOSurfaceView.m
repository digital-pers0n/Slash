//
//  MPVIOSurfaceView.m
//  Slash
//
//  Created by Terminator on 2020/06/13.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "MPVIOSurfaceView.h"
#import "MPVPlayer.h"
#import "MPVGLRenderer.h"

@import OpenGL.GL;
@import OpenGL.GL3;
@import QuartzCore.CATransaction;

#if __has_attribute(objc_direct)
#define OBJC_DIRECT __attribute__((objc_direct))
#define OBJC_DIRECT_MEMBERS __attribute__((objc_direct_members))
#else
#define OBJC_DIRECT
#define OBJC_DIRECT_MEMBERS
#endif

// Private CALayer API.
@interface CALayer (Private)
- (void)setContentsChanged;
@end

@interface MPVIOSurfaceView () {
    MPVGLRenderer _mpv;
    GLuint _texture;
    dispatch_queue_t _render_queue;
    __weak CALayer * _layer;
    NSOpenGLContext *_glContext;
    MPVPlayer *_player;
}

- (void)setUp OBJC_DIRECT;
- (void)playerWillShutdown:(NSNotification *)notification;

@end

OBJC_DIRECT_MEMBERS
@interface MPVIOSurfaceView (OpenGL)

- (NSOpenGLPixelFormat *)createOpenGLPixelFormat;
- (NSOpenGLContext *)createOpenGLContext:(NSOpenGLPixelFormat *)pf;
- (BOOL)initializeOpenGLContext;

@end

OBJC_DIRECT_MEMBERS
@interface MPVIOSurfaceView (MPVRenderer)

- (BOOL)createMPVPlayer;
- (int)createMPVRenderContext;
- (void)destroyMPVRenderContext;

@end

OBJC_DIRECT_MEMBERS
@interface MPVIOSurfaceView (IOSurface)

- (IOSurfaceRef)createIOSurface;
- (void)bindTextureToIOSurface:(IOSurfaceRef)ioSurface;
- (void)bindFramebuffer;
- (void)updateIOSurface;

@end

@implementation MPVIOSurfaceView

#pragma mark - Initialization

- (instancetype)initWithPlayer:(MPVPlayer *)player {

    self = [super init];
    if (self) {
        if (![self initializeOpenGLContext]) {
            return nil;
        }
        
        if (!player) {
            if (![self createMPVPlayer]) {
                NSLog(@"Cannot create MPVPlayer. %@",
                      _player.error.localizedDescription);
                return nil;
            }
        } else {
            _player = player;
        }
        
        [self setUp];
    }
    return self;
}

- (instancetype)initWithFrame:(NSRect)frame {
    self = [self initWithPlayer:nil];
    if (self) {
        self.frame = frame;
    }
    return self;
}

- (void)dealloc {
    [self destroyMPVRenderContext];
}

- (void)setUp {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver:self
           selector:@selector(playerWillShutdown:)
               name:MPVPlayerWillShutdownNotification
             object:_player];
    
    dispatch_queue_attr_t attr;
    attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL,
                                                   qos_class_main(), 0);
    
    _render_queue = dispatch_queue_create("com.home.MPVIOSurfaceView"
                                          ".render-queue", attr);
    
    CGColorRef blackColor = CGColorGetConstantColor(kCGColorBlack);
    CALayer *layer = [CALayer layer];
    layer.opaque = YES;
    layer.contentsGravity = kCAGravityResizeAspect;
    layer.backgroundColor = blackColor;
    layer.anchorPoint = CGPointZero;
    layer.position = CGPointZero;
    layer.bounds = CGRectMake(0, 0, 640, 480);
    layer.doubleSided = NO;
    self.wantsLayer = YES;
    self.layer.opaque = YES;
    self.layer.backgroundColor = blackColor;
    [self.layer addSublayer:layer];
    self.layerContentsRedrawPolicy =  NSViewLayerContentsRedrawDuringViewResize;
    _layer = layer;
}

#pragma mark - Overrides

- (BOOL)wantsUpdateLayer {
    return mpvgl_is_valid(&_mpv);
}

- (void)setFrame:(NSRect)frame {
    [super setFrame:frame];
    typeof(_mpv) *mpv = &_mpv;
    if (mpvgl_is_valid(mpv)) {
        NSSize size = [self convertSizeToBacking:frame.size];
        mpvgl_lock(mpv);
        mpvgl_set_size(mpv, size.width, size.height);
        mpvgl_unlock(mpv);
    }
}

- (void)updateLayer {
    if (self.inLiveResize) {
        typeof(_mpv) *mpv = &_mpv;
        mpvgl_lock(mpv);
        [self updateIOSurface];
        mpvgl_unlock(mpv);
    }
}

- (void)viewWillStartLiveResize {
    [super viewWillStartLiveResize];
    if (mpvgl_is_valid(&_mpv)) {
        mpvgl_set_update_callback(&_mpv, &resize_callback, (__bridge void *)self);
    }
}

- (void)viewDidEndLiveResize {
    [super viewDidEndLiveResize];
    if (mpvgl_is_valid(&_mpv)) {
        mpvgl_set_update_callback(&_mpv, &render_callback, (__bridge void *)self);
    }
}

#pragma mark - Notifications

- (void)playerWillShutdown:(NSNotification *)n {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self destroyMPVRenderContext];
}

#pragma mark - Callbacks

static void render(void *ctx) {
    __unsafe_unretained MPVIOSurfaceView *obj = (__bridge id)ctx;
    typeof(obj->_mpv) *mpv = &obj->_mpv;
    mpvgl_make_current(mpv);
    mpvgl_render(mpv);
    mpvgl_flush(mpv);
    [obj->_layer setContentsChanged];
    [CATransaction commit];
}

static void render_callback(void *ctx) {
    __unsafe_unretained MPVIOSurfaceView *obj = (__bridge id)ctx;
    dispatch_async_f(obj->_render_queue, ctx, &render);
}

static void resize(void *ctx) {
    __unsafe_unretained MPVIOSurfaceView *obj = (__bridge id)ctx;
    typeof(obj->_mpv) *mpv = &obj->_mpv;
    if (mpvgl_has_frame(mpv)) {
        mpvgl_lock(mpv);
        mpvgl_make_current(mpv);
        mpvgl_update(mpv);
        
        mpv_opengl_fbo fbo = mpv->fbo;
        int block_for_target = 0;
        mpv_render_param render_params[] = {
            {
                .type = MPV_RENDER_PARAM_OPENGL_FBO,
                .data = &fbo
            },
            {
                .type = MPV_RENDER_PARAM_BLOCK_FOR_TARGET_TIME,
                .data = &block_for_target
            },
            { 0 }
        };
        [CATransaction begin];
        mpvgl_render(mpv, render_params);
        [obj->_layer setContentsChanged];
        [CATransaction commit];
        
        mpvgl_flush(mpv);
        mpvgl_unlock(mpv);
    }
}

static void resize_callback(void *ctx) {
    __unsafe_unretained MPVIOSurfaceView *obj = (__bridge id)ctx;
    dispatch_async_f(obj->_render_queue, ctx, &resize);
}

@end

@implementation MPVIOSurfaceView (OpenGL)

- (NSOpenGLPixelFormat *)createOpenGLPixelFormat {
    NSOpenGLPixelFormatAttribute attributes[] = {
        NSOpenGLPFANoRecovery,
        NSOpenGLPFAAllowOfflineRenderers,
        NSOpenGLPFAAccelerated,
        
#if USE_DOUBLE_BUFFER_PIXEL_FORMAT
        
        NSOpenGLPFADoubleBuffer,
        
#endif
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
        0
    };
    
    return [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
}

- (NSOpenGLContext *)createOpenGLContext:(NSOpenGLPixelFormat *)pf {
    return [[NSOpenGLContext alloc] initWithFormat:pf shareContext:nil];
}

- (BOOL)initializeOpenGLContext {
    NSOpenGLPixelFormat *pf = [self createOpenGLPixelFormat];
    if (!pf) {
        NSLog(@"Cannot create NSOpenGLPixelFormat.");
        return NO;
    }
    
    NSOpenGLContext *glContext = [self createOpenGLContext:pf];
    if (!glContext) {
        NSLog(@"Cannot create NSOpenGLContext.");
        return NO;
    }
    
    GLint swapInt = 1;
    [glContext setValues:&swapInt
            forParameter:NSOpenGLContextParameterSwapInterval];
    GLint opaque = 1;
    [glContext setValues:&opaque forParameter:NSOpenGLCPSurfaceOpacity];
    
    _glContext = glContext;
    return YES;
}

@end

@implementation MPVIOSurfaceView (MPVRenderer)

- (BOOL)createMPVPlayer {
    _player = [[MPVPlayer alloc] init];
    if (_player.status == MPVPlayerStatusFailed) {
        return NO;
    }
    return YES;
}

- (int)createMPVRenderContext {
    
    int error = mpvgl_init(&_mpv, _player.mpv_handle,
                           _glContext.CGLContextObj, false);
    
    if (error) {
        return error;
    }
    
    if (NSAppKitVersionNumber < NSAppKitVersionNumber10_12) {
        // Fix the black screen and flickering under 10.11
        static int flag = 0;
        mpv_render_param param = {
            .type = MPV_RENDER_PARAM_BLOCK_FOR_TARGET_TIME,
            .data = &flag
        };
        mpvgl_set_aux_parameter(&_mpv, param);
    }
    
    return 0;
}

- (void)destroyMPVRenderContext {
    mpvgl_destroy(&_mpv);
}

@end

@implementation MPVIOSurfaceView (IOSurface)

- (IOSurfaceRef)createIOSurface {
    NSDictionary* dict = @{
                           (id)kIOSurfaceWidth: @(_mpv.fbo.w),
                           (id)kIOSurfaceHeight: @(_mpv.fbo.h),
                           (id)kIOSurfaceBytesPerElement: @4,
                           (id)kIOSurfacePixelFormat:
                               @((int)kCVPixelFormatType_32BGRA),
                           };
    return IOSurfaceCreate((CFDictionaryRef)dict);
}

- (void)bindTextureToIOSurface:(IOSurfaceRef)ioSurface {
    if (_texture) {
        glDeleteTextures(1, &_texture);
        _texture = 1;
    }
    
    GLuint texture;
    glGenTextures(1, &texture);
    
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, texture);
    
    CGLError rv =
    CGLTexImageIOSurface2D(_mpv.cgl, GL_TEXTURE_RECTANGLE_ARB,
                           GL_RGBA, // internal format
                           (GLsizei)_mpv.fbo.w,
                           (GLsizei)_mpv.fbo.h,
                           GL_BGRA, // format
                           GL_UNSIGNED_INT_8_8_8_8_REV, // type
                           ioSurface, 0);
    
    if (rv != 0) {
        NSLog(@"CGLError: %d", rv);
    }
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, 0);
    
    _texture = texture;
}

- (void)bindFramebuffer {
    if (_mpv.fbo.fbo) {
        glDeleteFramebuffers(1, (const GLuint *)&_mpv.fbo.fbo);
        _mpv.fbo.fbo = 0;
    }
    
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _texture);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                           GL_TEXTURE_RECTANGLE_ARB, _texture, 0);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Framebuffer incomplete: %u", status);
    }
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, 0);
    
    _mpv.fbo.fbo = framebuffer;
}

- (void)updateIOSurface {
    typeof(_mpv) *mpv = &_mpv;
    
    mpvgl_make_current(mpv);
    
    IOSurfaceRef surface = [self createIOSurface];
    [self bindTextureToIOSurface:surface];
    [self bindFramebuffer];
    
    int block_for_target = 0;
    mpv_opengl_fbo fbo = _mpv.fbo;
    mpv_render_param render_params[] = {
        {
            .type = MPV_RENDER_PARAM_OPENGL_FBO,
            .data = &fbo
        },
        {
            .type = MPV_RENDER_PARAM_BLOCK_FOR_TARGET_TIME,
            .data = &block_for_target
        },
        { 0 }
    };
    
    [CATransaction begin];
    [CATransaction setValue:@YES forKey:kCATransactionDisableActions];
    
    mpvgl_render(mpv, render_params);
    mpvgl_flush(mpv);
    
    _layer.bounds = CGRectMake(0, 0, fbo.w, fbo.h);
    _layer.contents = (id)CFAutorelease(surface);
    
    [CATransaction commit];
}

@end

