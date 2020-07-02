//
//  SLHPlayerView.m
//  Slash
//
//  Created by Terminator on 2019/10/15.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHPlayerView.h"
#import "MPVPlayer.h"
#import "MPVPlayerProperties.h"
#import "MPVPlayerItem.h"
#import "MPVOpenGLView.h"
#import "MPVIOSurfaceView.h"
#import "SLHPlayerViewController.h"
#import "SLHMethodAddress.h"
#import "SLHPreferences.h"
#import "SLHPreferencesKeys.h"

@interface SLHPlayerView () {
    MPVPlayer *_player;
    MPVOpenGLView *_videoView;
    Class _videoViewClass;
    SLHPlayerViewController *_viewController;
    NSDictionary <NSString *, SLHMethodAddress *> *_observedPrefs;
    
    struct _playerViewFlags {
        unsigned int shouldPauseDuringLiveResize:1;
        unsigned int shouldResumePlayback:1;
    } _PVFlags;
}

@end

@implementation SLHPlayerView

#pragma mark - Initialization

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUp];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setUp];
    }
    return self;
}

- (void)setUp {
    
    _viewController = [[SLHPlayerViewController alloc] init];
    NSView *controlsView = _viewController.view;
    controlsView.frame = self.bounds;
    controlsView.autoresizingMask =   NSViewWidthSizable | NSViewHeightSizable;
    [self addSubview:controlsView];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(cleanUp:) name:NSApplicationWillTerminateNotification object:NSApp];
    SLHPreferences *prefs = [SLHPreferences preferences];
    BOOL flag = prefs.pausePlaybackDuringWindowResize;
    _PVFlags.shouldPauseDuringLiveResize = flag ? 1 : 0;
    [self observePreferences:prefs];
    Class cls = NSClassFromString(prefs.rendererClassName);
    if (!cls) {
        cls = MPVOpenGLView.class;
    }
    _videoViewClass = cls;
}

- (void)dealloc {
    [self shutdown];
}

#pragma mark - Methods

- (BOOL)isReadyForDisplay {
    return (_player && _videoView && _player.status == MPVPlayerStatusReadyToPlay);
}

- (MPVPlayer *)player {
    return _player;
}

- (void)setPlayer:(MPVPlayer *)player {
    
    if (player == _player) {
        return;
    }
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    if (_player) {
        [nc removeObserver:self name:MPVPlayerWillShutdownNotification object:_player];
    }
    
    if (player) {
        [nc addObserver:self selector:@selector(cleanUp:) name:MPVPlayerWillShutdownNotification object:player];
        if (!_videoView) {
            [self createVideoViewWithPlayer:player];
        } else {
            _videoView.player = player;
        }
        _viewController.player = player;
    } else {
        _videoView.player = nil;
        _viewController.player = nil;
    }
    _player = player;
}

- (void)createVideoViewWithPlayer:(MPVPlayer *)player {
    NSError *error = nil;
    NSRect frame = _viewController.videoView.bounds;

    _videoView = [[_videoViewClass alloc] initWithFrame:frame
                                                 player:player error:&error];
    if (error) {
        NSLog(@"Error %@", error);
        [NSApp presentError:error];
        return;
    }
    _videoView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [_viewController.videoView addSubview:_videoView];
    BOOL flag = [[SLHPreferences preferences] useHiResOpenGLSurface];
    _videoView.wantsBestResolutionOpenGLSurface = flag;
}

- (void)shutdown {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self unobservePreferences:[SLHPreferences preferences]];
    
    [_videoView removeFromSuperview];
    [_viewController.view removeFromSuperview];
    _videoView.player = nil;
    _viewController.player = nil;
    _player = nil;
}

#pragma mark - Notifications

- (void)cleanUp:(NSNotification *)n {
    [self shutdown];
}

#pragma mark - Overrides

- (void)viewWillStartLiveResize {
    [super viewWillStartLiveResize];
    if (_player && _PVFlags.shouldPauseDuringLiveResize) {
        if ([_player isPaused]) {
            _PVFlags.shouldResumePlayback = 0;
        } else {
            _PVFlags.shouldResumePlayback = 1;
            [_player pause];
        }
    }
}

- (void)viewDidEndLiveResize {
    [super viewDidEndLiveResize];
    if (_player && _PVFlags.shouldPauseDuringLiveResize) {
        if (_PVFlags.shouldResumePlayback) {
            [_player play];
        }
    }
}

#pragma mark - KVO

- (void)didChangePauseDuringLiveResize:(NSNumber *)value {
    _PVFlags.shouldPauseDuringLiveResize = (value.boolValue) ? 1 : 0;
}

- (void)didChangeUseHiResOpenGLSurface:(NSNumber *)value {
    if (_videoView) {
        _videoView.wantsBestResolutionOpenGLSurface = value.boolValue;
    }
}

- (void)didChangeRendererName:(NSString *)name {
    if (!_player) { return; }
    
    MPVPlayerItem *item = _player.currentItem;
    NSInteger vid = 0;
    if (item) {
        vid = [_player integerForProperty:MPVPlayerPropertyVideoID];
        [_player setString:@"no" forProperty:MPVPlayerPropertyVideoID];
    }
    [_videoView removeFromSuperview];
    [_videoView destroyRenderContext];
    _videoView = nil;
    _videoViewClass = NSClassFromString(name);
    [self createVideoViewWithPlayer:_player];
    
    if (item) {
        [_player setInteger:vid forProperty:MPVPlayerPropertyVideoID];
    }
}

static char SLHPlayerViewKVOContext;

- (void)observePreferences:(SLHPreferences *)appPrefs {
    _observedPrefs = @{
                       SLHPreferencesPausePlaybackDuringWindowResizeKey :
                           addressOf(self, @selector(didChangePauseDuringLiveResize:)),
                       SLHPreferencesUseHiResOpenGLSurfaceKey :
                           addressOf(self, @selector(didChangeUseHiResOpenGLSurface:)),
                       SLHPreferencesRendererClassNameKey :
                           addressOf(self, @selector(didChangeRendererName:))
                       
                       };
    
    for (NSString *key in _observedPrefs) {
        [appPrefs addObserver:self
                   forKeyPath:key
                      options:NSKeyValueObservingOptionNew
                      context:&SLHPlayerViewKVOContext];
    }
}

- (void)unobservePreferences:(SLHPreferences *)appPrefs {
    for (NSString *key in _observedPrefs) {
        [appPrefs removeObserver:self
                      forKeyPath:key
                         context:&SLHPlayerViewKVOContext];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context
{
    if (context == &SLHPlayerViewKVOContext) {
        SLHMethodAddress *method = _observedPrefs[keyPath];
        if (method) {
            ((SLHSetterIMP)method->_impl)(self,
                                          method->_selector,
                                          change[NSKeyValueChangeNewKey]);
        }
    } else {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}

@end
