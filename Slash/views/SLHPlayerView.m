//
//  SLHPlayerView.m
//  Slash
//
//  Created by Terminator on 2019/10/15.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHPlayerView.h"
#import "MPVPlayer.h"
#import "MPVOpenGLView.h"
#import "SLHPlayerViewController.h"

@interface SLHPlayerView () {
    MPVPlayer *_player;
    MPVOpenGLView *_videoView;
    SLHPlayerViewController *_viewController;
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
    _videoView = [[MPVOpenGLView alloc] initWithPlayer:player];
    assert(_videoView != nil);
    _videoView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    _videoView.frame = _viewController.videoView.bounds;
    [_viewController.videoView addSubview:_videoView];
}

- (void)shutdown {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
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

@end
