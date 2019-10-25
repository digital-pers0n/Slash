//
//  SLHPlayerViewInlineController.m
//  Slash
//
//  Created by Terminator on 2019/10/16.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHPlayerViewController.h"
#import "MPVPlayer.h"
#import "MPVPlayerProperties.h"
#import "MPVPlayerCommands.h"

#define bindObject(obj, value, keyPath) [obj bind:@#value toObject:self withKeyPath:@#keyPath options:nil]

@interface SLHPlayerViewController () <MPVPropertyObserving, NSControlTextEditingDelegate> {
    MPVPlayer *_player;
    double _currentPosition;
    IBOutlet NSTextField *_textField;
    IBOutlet NSSlider *_seekBar;
    
    dispatch_queue_t _timer_queue;
    dispatch_source_t _timer;
}

@property (nonatomic) double duration;
@property (nonatomic) double currentPosition;
@property (nonatomic) BOOL seekable;

@end

@implementation SLHPlayerViewController

- (NSString *)nibName {
    return self.className;
}

#pragma mark - Properties

- (MPVPlayer *)player {
    return _player;
}

- (void)setPlayer:(MPVPlayer *)player {
    if (player == _player) { return; }
    
    if (_player) {
        [self removeObserverForPlayer:_player];
    }
    
    if (player) {
        [self addObserverForPlayer:player];
    } else {
        if (_timer) {
            dispatch_cancel(_timer);
            _timer = nil;
        }
    }
    
    _player = player;
}

#pragma mark - Methods

- (void)removeObserverForPlayer:(MPVPlayer *)player {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:player];
}

- (void)addObserverForPlayer:(MPVPlayer *)player {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(playerDidLoadFile:) name:MPVPlayerDidLoadFileNotification object:player];
}

- (void)createTimerWithInterval:(NSUInteger)seconds {
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _timer_queue);
    dispatch_set_context(_timer, (__bridge void*)self);
    dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC, 0.5 * NSEC_PER_SEC);
    dispatch_source_set_event_handler_f(_timer, &timer_handler);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _timer_queue = dispatch_get_main_queue();
    bindObject(_textField, doubleValue, self.currentPosition);
    bindObject(_seekBar, doubleValue, self.currentPosition);
    bindObject(_textField, enabled, self.seekable);
    bindObject(_seekBar, enabled, self.seekable);
}

#pragma mark - IBActions

- (IBAction)stepBack:(id)sender {
    [_player performCommand:MPVPlayerCommandFrameBackStep];
}

- (IBAction)stepForward:(id)sender {
    [_player performCommand:MPVPlayerCommandFrameStep];
}

- (IBAction)play:(id)sender {
    BOOL state = [_player boolForProperty:MPVPlayerPropertyPause];
    if (state) {
        [_player play];
    } else {
        [_player pause];
    }
}

- (IBAction)seek:(id)sender {
    [_player seekTo:_currentPosition];
}

#pragma mark - Notifications

- (void)playerDidLoadFile:(NSNotification *)n {
    double duration = [_player doubleForProperty:MPVPlayerPropertyDuration];
    if (duration > 0) {
        [self createTimerWithInterval:1];
        dispatch_resume(_timer);
        self.seekable = YES;
    } else {
        self.seekable = NO;
    }
    self.duration = duration;
}

- (void)playerDidEndPlayback:(NSNotification *)n {
    if (_timer) {
        dispatch_cancel(_timer);
        _timer = nil;
    }
}


#pragma mark - NSControlTextEditingDelegate

- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor {
    [control unbind:@"doubleValue"];
    return YES;
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
    _player.timePosition = control.doubleValue;
    bindObject(control, doubleValue, self.currentPosition);
    return YES;
}

#pragma mark - MPVPropertyObserving

- (void)player:(MPVPlayer *)player didChangeValue:(id)value forProperty:(NSString *)property format:(mpv_format)format {
    
}

#pragma mark - dispatch source timer handler

static void timer_handler(void *ctx) {
    __unsafe_unretained SLHPlayerViewController *obj = (__bridge id)ctx;
    obj.currentPosition = obj->_player.timePosition;
}

@end
