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
#import <dlfcn.h>

@import OpenGL.GL;
@import OpenGL.GL3;
@import QuartzCore.CATransaction;
@import CoreVideo.CVDisplayLink;

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
- (void)reloadValueForKeyPath:(NSString *)keyPath;
@end

@interface MPVIOSurfaceView () {
    MPVGLRenderer _mpv;
    GLuint _texture;
    dispatch_queue_t _render_queue;
    __weak CALayer * _layer;
    CFMutableDictionaryRef _ioProperties;
    MPVPlayer *_player;
    CVDisplayLinkRef _cvdl;
    CGLContextObj _cgl;
}

- (NSError *)setUp OBJC_DIRECT;
- (void)playerWillShutdown:(NSNotification *)notification;

@end

OBJC_DIRECT_MEMBERS
@interface MPVIOSurfaceView (OpenGL)

- (CGLError)createOpenGLPixelFormat:(CGLPixelFormatObj *)pix;
- (CGLError)createOpenGLContext:(CGLContextObj *)cgl
                     withFormat:(CGLPixelFormatObj)pix;
- (NSError *)initializeOpenGLContext;

@end

OBJC_DIRECT_MEMBERS
@interface MPVIOSurfaceView (MPVRenderer)

- (BOOL)createMPVPlayer;
- (NSError *)createMPVRenderContext;
- (void)destroyMPVRenderContext;
- (void)useRenderCallback;
- (void)removeCallback;

@end

OBJC_DIRECT_MEMBERS
@interface MPVIOSurfaceView (IOSurface)

- (CFMutableDictionaryRef)createIOSurfaceProperties;
- (IOSurfaceRef)createIOSurface;
- (void)bindTextureToIOSurface:(IOSurfaceRef)ioSurface;
- (void)bindFramebuffer;
- (void)updateIOSurface;

@end

OBJC_DIRECT_MEMBERS
@interface MPVIOSurfaceView (DisplayLink)

- (void)setUpDisplayLink;
- (void)startDisplayLink;
- (void)stopDisplayLink;
- (void)destroyDisplayLink;

@end

OBJC_DIRECT_MEMBERS
@interface MPVIOSurfaceView (Errors)

- (NSError *)cglPixelFormatErrorWithCode:(CGLError)code;
- (NSError *)cglContextErrorWithCode:(CGLError)code;
- (NSError *)mpvRenderContextErrorWithCode:(int)code;
- (NSDictionary *)userInfoWithDescription:(NSString *)description
                               suggestion:(NSString *)suggestion;

@end

@implementation MPVIOSurfaceView

#pragma mark - Initialization

- (instancetype)initWithPlayer:(MPVPlayer *)player {

    self = [super initWithFrame:NSMakeRect(0, 0, 640, 480)];
    if (self) {
        _player = player;
        NSError *error = [self setUp];
        if (error) {
            [NSApp presentError:error];
            return nil;
        }
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
    [self destroyDisplayLink];
    [self destroyMPVRenderContext];
    if (_ioProperties) {
        CFRelease(_ioProperties);
    }
    if (_cgl) {
        CGLReleaseContext(_cgl);
    }
}

- (NSError *)setUp {
    NSError * result = nil;
    result = [self initializeOpenGLContext];
    
    if (result) {
        return result;
    }
    
    if (!_player) {
        if (![self createMPVPlayer]) {
            return _player.error;
        }
    }
    
    result = [self createMPVRenderContext];
    if (result) {
        return result;
    }
    
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
    [self setUpDisplayLink];
    
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
    
    _ioProperties = [self createIOSurfaceProperties];
    return result;
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
    typeof(_mpv) *mpv = &_mpv;
    if (CVDisplayLinkIsRunning(_cvdl)) {
        mpvgl_lock(mpv);
        [self updateIOSurface];
        mpvgl_unlock(mpv);
    } else {
         __unsafe_unretained typeof(self) obj = self;
        dispatch_async(_render_queue, ^{
            [obj updateIOSurface];
            mpvgl_update(mpv);
        });
    }
}

- (void)viewWillStartLiveResize {
    [super viewWillStartLiveResize];
    if (mpvgl_is_valid(&_mpv)) {
        [self removeCallback];
        [self startDisplayLink];
    }
}

- (void)viewDidEndLiveResize {
    [super viewDidEndLiveResize];
    if (mpvgl_is_valid(&_mpv)) {
        [self stopDisplayLink];
        [self useRenderCallback];
    }
}

#pragma mark - Notifications

- (void)playerWillShutdown:(NSNotification *)n {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self destroyMPVRenderContext];
}

#pragma mark - Callbacks

static void update_layer_contents(__unsafe_unretained CALayer *layer) {
    [layer reloadValueForKeyPath:@"contents"];
}

static void render(void *ctx) {
    __unsafe_unretained MPVIOSurfaceView *obj = (__bridge id)ctx;
    typeof(obj->_mpv) *mpv = &obj->_mpv;
    mpvgl_make_current(mpv);
    mpvgl_render(mpv);
    mpvgl_flush(mpv);
    update_layer_contents(obj->_layer);
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
        update_layer_contents(obj->_layer);
        [CATransaction commit];
        
        mpvgl_flush(mpv);
        mpvgl_unlock(mpv);
    }
}

static CVReturn cvdl_cb(
                        CVDisplayLinkRef CV_NONNULL displayLink,
                        const CVTimeStamp * CV_NONNULL inNow,
                        const CVTimeStamp * CV_NONNULL inOutputTime,
                        CVOptionFlags flagsIn,
                        CVOptionFlags * CV_NONNULL flagsOut,
                        void * CV_NULLABLE displayLinkContext ) {
    resize(displayLinkContext);
    return kCVReturnSuccess;
}

@end

@implementation MPVIOSurfaceView (OpenGL)

- (CGLError)createOpenGLPixelFormat:(CGLPixelFormatObj *)pix {
    CGLPixelFormatAttribute glAttributes[] = {
        kCGLPFAOpenGLProfile, (CGLPixelFormatAttribute)kCGLOGLPVersion_3_2_Core,
        kCGLPFAAccelerated,
#if USE_DOUBLE_BUFFER_PIXEL_FORMAT
        kCGLPFADoubleBuffer,
#endif
        kCGLPFAAllowOfflineRenderers,
        kCGLPFASupportsAutomaticGraphicsSwitching,
        0
    };
    GLint npix = 0;
    return CGLChoosePixelFormat(glAttributes, pix, &npix);
}

- (CGLError)createOpenGLContext:(CGLContextObj *)cgl
                     withFormat:(CGLPixelFormatObj)pix
{
    return CGLCreateContext(pix, nil, cgl);
}

- (NSError *)initializeOpenGLContext {
    CGLPixelFormatObj pix = nil;
    CGLError error = [self createOpenGLPixelFormat:&pix];
    if (error) {
        return [self cglPixelFormatErrorWithCode:error];
    }
    
    CGLContextObj cgl = nil;
    error = [self createOpenGLContext:&cgl withFormat:pix];
    if (error) {
        CGLReleasePixelFormat(pix);
        return [self cglContextErrorWithCode:error];
    }
    CGLReleasePixelFormat(pix);
    
    GLint swapInt = 1;
    CGLSetParameter(cgl, kCGLCPSwapInterval, &swapInt);
    _cgl = cgl;
    return nil;
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

- (NSError *)createMPVRenderContext {
    
    int error = mpvgl_init(&_mpv, _player.mpv_handle, _cgl, false);
    
    if (error) {
        return [self mpvRenderContextErrorWithCode:error];
    }
    _mpv.fbo.internal_format = GL_RGBA;
    
    // This was previously intended to fix black screen under macOS 10.11
    // But the black screen appears on Mojave too, if videotoolbox is not used.
    // So make this parameter always on.
    static int flag = 0;
    mpv_render_param param = {
        .type = MPV_RENDER_PARAM_BLOCK_FOR_TARGET_TIME,
        .data = &flag
    };
    mpvgl_set_aux_parameter(&_mpv, param);
    return nil;
}

- (void)destroyMPVRenderContext {
    mpvgl_destroy(&_mpv);
}

- (void)useRenderCallback {
    mpvgl_set_update_callback(&_mpv, &render_callback, (__bridge void *)self);
}

- (void)removeCallback {
    mpvgl_reset_update_callback(&_mpv);
}

@end

@implementation MPVIOSurfaceView (IOSurface)

- (CFMutableDictionaryRef)createIOSurfaceProperties {
    CFMutableDictionaryRef dict;
    dict = CFDictionaryCreateMutable(kCFAllocatorDefault, 4,
                                     &kCFTypeDictionaryKeyCallBacks,
                                     &kCFTypeDictionaryValueCallBacks);
    CFNumberRef num;
    num = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, (int[]){4});
    CFDictionarySetValue(dict, kIOSurfaceBytesPerElement, CFAutorelease(num));
    
    num = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType,
                         (int[]){kCVPixelFormatType_32BGRA});
    CFDictionarySetValue(dict, kIOSurfacePixelFormat, CFAutorelease(num));
    return dict;
}

- (IOSurfaceRef)createIOSurface {
    CFNumberRef num;
    num = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &_mpv.fbo.w);
    CFDictionarySetValue(_ioProperties, kIOSurfaceWidth, num);
    CFRelease(num);
    num = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &_mpv.fbo.h);
    CFDictionarySetValue(_ioProperties, kIOSurfaceHeight, num);
    CFRelease(num);
    return IOSurfaceCreate(_ioProperties);
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
    [CATransaction setValue:(id)kCFBooleanTrue
                     forKey:kCATransactionDisableActions];
    
    mpvgl_render(mpv, render_params);
    mpvgl_flush(mpv);
    
    _layer.bounds = CGRectMake(0, 0, fbo.w, fbo.h);
    _layer.contents = (id)CFAutorelease(surface);
    
    [CATransaction commit];
}

@end

@implementation MPVIOSurfaceView (DisplayLink)

- (void)setUpDisplayLink {
    CVDisplayLinkCreateWithActiveCGDisplays(&_cvdl);
    CVDisplayLinkSetOutputCallback(_cvdl, &cvdl_cb, (__bridge void *)self);
}

- (void)startDisplayLink {
    CVDisplayLinkStart(_cvdl);
}

- (void)stopDisplayLink {
    CVDisplayLinkStop(_cvdl);
}

- (void)destroyDisplayLink {
    CVDisplayLinkRelease(_cvdl);
}

@end

@implementation MPVIOSurfaceView (Errors)

- (NSError *)cglPixelFormatErrorWithCode:(CGLError)err {
    NSDictionary *info;
    info = [self userInfoWithDescription:@"Cannot initialize OpenGL Pixel Format."
                              suggestion:@(CGLErrorString(err))];
    return [NSError errorWithDomain:MPVPlayerErrorDomain code:err userInfo:info];
}
- (NSError *)cglContextErrorWithCode:(CGLError)err {
    NSDictionary *info;
    info = [self userInfoWithDescription:@"Cannot initialize OpenGL Context."
                              suggestion:@(CGLErrorString(err))];
    return [NSError errorWithDomain:MPVPlayerErrorDomain code:err userInfo:info];
}

- (NSError *)mpvRenderContextErrorWithCode:(int)err {
    NSDictionary *info;
    if (MPVGL_ERROR_OPENGL_FRAMEWORK_UNAVAILABLE == err) {
        NSString *desc = @"Cannot load OpenGL.framework";
        const char *error = dlerror();
        if (error) {
            info = [self userInfoWithDescription:desc suggestion:@(error)];
        } else {
            id string = [NSString stringWithFormat:@"Error while loading '%s'",
                                                   MPVGL_OPENGL_FRAMEWORK_PATH];
            info = [self userInfoWithDescription:desc suggestion:string];
        }
        
    } else {
        info = [self userInfoWithDescription:@"Cannot initialize mpv render context."
                                  suggestion:@(mpv_error_string(err))];
    }
    return [NSError errorWithDomain:MPVPlayerErrorDomain code:err userInfo:info];
}

- (NSDictionary *)userInfoWithDescription:(NSString *)description
                               suggestion:(NSString *)reason
{
    return @{ NSLocalizedDescriptionKey             : description,
              NSLocalizedRecoverySuggestionErrorKey : reason };
}

@end

