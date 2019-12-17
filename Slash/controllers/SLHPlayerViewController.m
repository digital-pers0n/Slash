//
//  SLHPlayerViewInlineController.m
//  Slash
//
//  Created by Terminator on 2019/10/16.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHPlayerViewController.h"
#import "SLHSliderCell.h"

#import "MPVPlayer.h"
#import "MPVPlayerItem.h"
#import "MPVPlayerItemTrack.h"
#import "MPVPlayerProperties.h"
#import "MPVPlayerCommands.h"

#define bindObject(obj, value, keyPath) [obj bind:@#value toObject:self withKeyPath:@#keyPath options:nil]

typedef NS_ENUM(NSUInteger, SLHVolumeIcon) {
    SLHVolumeIconMax,
    SLHVolumeIconMid,
    SLHVolumeIconMin,
    SLHVolumeIconMute
};

@interface SLHPlayerViewController () <MPVPropertyObserving, NSControlTextEditingDelegate, SLHSliderCellMouseTrackingDelegate> {
    MPVPlayer *_player;
    double _currentPosition;
    IBOutlet NSTextField *_textField;
    IBOutlet NSSlider *_seekBar;
    IBOutlet NSPopover *_volumePopover;
    
    BOOL _canSeek;
    BOOL _hasABLoop;
    BOOL _isAudioMuted;
    
    NSArray *_volumeButtonIcons;
    SLHVolumeIcon _currentVolumeIcon;
    
    dispatch_queue_t _seek_queue;
    dispatch_queue_t _timer_queue;
    dispatch_source_t _timer;
}

@property (nonatomic) double duration;
@property (nonatomic) double currentPosition;
@property (nonatomic) BOOL seekable;
@property (nonatomic) BOOL hasABLoop;
@property (nonatomic) BOOL hasAudio;
@property (nonatomic) NSImage *volumeButtonIcon;
@property (nonatomic) NSInteger volume;
@property (nonatomic) NSNotificationCenter *notificationCenter;

@end

@implementation SLHPlayerViewController

- (NSString *)nibName {
    return self.className;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _notificationCenter = [NSNotificationCenter defaultCenter];
    }
    return self;
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
    [self willChangeValueForKey:@"volume"];
    
    _player = player;
    
    [self didChangeValueForKey:@"volume"];
}

- (void)setVolume:(NSInteger)volume {
    if (!_isAudioMuted) {
        if (volume >= 75 &&
            _currentVolumeIcon != SLHVolumeIconMax) {
            
            self.volumeButtonIcon = _volumeButtonIcons[SLHVolumeIconMax];
            _currentVolumeIcon = SLHVolumeIconMax;
            
        } else if (volume < 75 &&
                   volume >= 25 &&
                   _currentVolumeIcon != SLHVolumeIconMid) {
            
            self.volumeButtonIcon = _volumeButtonIcons[SLHVolumeIconMid];
            _currentVolumeIcon = SLHVolumeIconMid;
            
        } else if (volume < 25 &&
                   _currentVolumeIcon != SLHVolumeIconMin) {
            
            self.volumeButtonIcon = _volumeButtonIcons[SLHVolumeIconMin];
            _currentVolumeIcon = SLHVolumeIconMin;
        }
    }
    _player.volume = volume;
}

- (NSInteger)volume {
    return _player.volume;
}

- (void)dealloc {
    SLHSliderCell *cell = _seekBar.cell;
    [cell unbind:@"inMark"];
    [cell unbind:@"outMark"];
    cell.delegate = nil;
}

#pragma mark - Methods

- (BOOL)hasAudioStreams {
    for (MPVPlayerItemTrack *track in _player.currentItem.tracks) {
        if (track.mediaType == MPVMediaTypeAudio) {
            return YES;
        }
    }
    return NO;
}

- (void)removeObserverForPlayer:(MPVPlayer *)player {
    [_notificationCenter removeObserver:self name:nil object:player];
}

- (void)addObserverForPlayer:(MPVPlayer *)player {
    NSNotificationCenter *nc = _notificationCenter;
    [nc addObserver:self selector:@selector(playerDidLoadFile:) name:MPVPlayerDidLoadFileNotification object:player];
    [nc addObserver:self selector:@selector(playerDidEndPlayback:) name:MPVPlayerDidEndPlaybackNotification object:player];
   [nc addObserver:self selector:@selector(playerDidRestartPlayback:) name:MPVPlayerDidRestartPlaybackNotification object:player];
    [nc addObserver:self selector:@selector(playerDidStartSeek:) name:MPVPlayerDidStartSeekNotification object:player];
}

- (void)createTimerWithInterval:(NSUInteger)seconds {
    if (_timer) {
        dispatch_cancel(_timer);
    }
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _timer_queue);
    dispatch_set_context(_timer, (__bridge void*)self);
    dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC, 0.5 * NSEC_PER_SEC);
    dispatch_source_set_event_handler_f(_timer, &timer_handler);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _timer_queue = dispatch_get_main_queue();
    
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(
                                                                         DISPATCH_QUEUE_SERIAL,
                                                                         QOS_CLASS_USER_INTERACTIVE, 0);
    _seek_queue = dispatch_queue_create("com.home.SLHPlayerViewController.seek-queue", attr);

    bindObject(_textField, doubleValue, self.currentPosition);
    bindObject(_seekBar, doubleValue, self.currentPosition);
    bindObject(_textField, enabled, self.seekable);
    bindObject(_seekBar, enabled, self.seekable);
    SLHSliderCell *sliderCell = _seekBar.cell;
    
    sliderCell.delegate = self;
    bindObject(sliderCell, inMark, self.inMark);
    bindObject(sliderCell, outMark, self.outMark);
    [self.view.window makeFirstResponder:self.view];
    
    NSImage *volumeMax = [NSImage imageNamed:@"SLHImageNameVolumeMaxTemplate"];
    NSImage *volumeMute = [NSImage imageNamed:@"SLHImageNameVolumeMuteTemplate"];
    NSImage *volumeMin = [NSImage imageNamed:@"SLHImageNameVolumeMinTemplate"];
    NSImage *volumeMid = [NSImage imageNamed:@"SLHImageNameVolumeMidTemplate"];
    _volumeButtonIcons = @[ volumeMax, volumeMid, volumeMin, volumeMute ];
    self.volumeButtonIcon = _volumeButtonIcons[SLHVolumeIconMax];
    
}

#pragma mark - IBActions

- (IBAction)stepBack:(id)sender {
    [_player performCommand:MPVPlayerCommandFrameBackStep];
}

- (IBAction)stepForward:(id)sender {
    [_player performCommand:MPVPlayerCommandFrameStep];
}

- (IBAction)inMark:(id)sender {
    
    self.inMark = _player.timePosition;
    [_notificationCenter postNotificationName:SLHPlayerViewControllerDidChangeInMarkNotification object:self userInfo:nil];
    
    if (_inMark > _outMark) {
        self.outMark = _player.currentItem.duration;
        [_notificationCenter postNotificationName:SLHPlayerViewControllerDidChangeOutMarkNotification object:self userInfo:nil];
    }
    _seekBar.needsDisplay = YES;
}

- (IBAction)outMark:(id)sender {
    
    self.outMark = _player.timePosition;
    [_notificationCenter postNotificationName:SLHPlayerViewControllerDidChangeOutMarkNotification object:self userInfo:nil];
    
    if (_outMark < _inMark) {
        self.inMark = 0;
        [_notificationCenter postNotificationName:SLHPlayerViewControllerDidChangeInMarkNotification object:self userInfo:nil];
    }
    _seekBar.needsDisplay = YES;
}

- (IBAction)loopPlayback:(id)sender {
    if (_hasABLoop) {
        [_player setDouble:_inMark forProperty:MPVPlayerPropertyABLoopA];
        [_player setDouble:_outMark forProperty:MPVPlayerPropertyABLoopB];
        _player.timePosition = _inMark;
    } else {
        [_player setString:@"no" forProperty:MPVPlayerPropertyABLoopA];
    }
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
    [_player seekTo:[sender doubleValue]];
}

- (IBAction)showVolumePopover:(NSButton *)sender {
    [_volumePopover showRelativeToRect:sender.frame ofView:sender.superview preferredEdge:NSMinYEdge];
}

- (IBAction)muted:(id)sender {
    if (_player.muted) {
        [self unmute];
    } else {
        [self mute];
    }
}

- (void)unmute {
    _player.muted = NO;
    _isAudioMuted = NO;
    self.volume = _player.volume;
}

- (void)mute {
    _player.muted = YES;
    _isAudioMuted = YES;
    self.volumeButtonIcon = _volumeButtonIcons[SLHVolumeIconMute];
    _currentVolumeIcon = SLHVolumeIconMute;
}

- (IBAction)resetVolumeLevel:(id)sender {
    if (_player.muted) {
        [self unmute];
    }
    [self willChangeValueForKey:@"volume"];
    _player.volume = 100;
    [self didChangeValueForKey:@"volume"];
    self.volumeButtonIcon = _volumeButtonIcons[SLHVolumeIconMax];
    _currentVolumeIcon = SLHVolumeIconMax;
}

#pragma mark - Notifications

- (void)playerDidLoadFile:(NSNotification *)n {
    double duration = _player.currentItem.duration;
    if (duration > 0) {
        [self createTimerWithInterval:1];
        dispatch_resume(_timer);
        self.seekable = YES;
    } else {
        self.seekable = NO;
    }
    self.duration = duration;
    self.inMark = 0;
    self.outMark = 0;
    if (_hasABLoop) {
         [_player setString:@"no" forProperty:MPVPlayerPropertyABLoopA];
         self.hasABLoop = NO;
    }
    self.hasAudio = [self hasAudioStreams];
}

- (void)playerDidEndPlayback:(NSNotification *)n {
    if (_timer) {
        dispatch_cancel(_timer);
        _timer = nil;
    }
    self.seekable = NO;
    self.currentPosition = 0;
    self.duration = 0;
}

- (void)playerDidRestartPlayback:(NSNotification *)n {
    if (!_canSeek) {
        [_player seekExactTo:_seekBar.doubleValue];
        _canSeek = YES;
    }
}

- (void)playerDidStartSeek:(NSNotification *)n {
    self.currentPosition = _player.timePosition;
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

#pragma mark - SLHSliderCellMouseTracking

- (void)sliderCellMouseUp:(SLHSliderCell *)cell {
   _player.timePosition = cell.doubleValue;
    self.currentPosition = cell.doubleValue;
    dispatch_resume(_timer);
    bindObject(_seekBar, doubleValue, self.currentPosition);
}

- (void)sliderCellMouseDown:(SLHSliderCell *)cell {
    dispatch_suspend(_timer);
    [_seekBar unbind:@"doubleValue"];
}

- (void)sliderCellMouseDragged:(SLHSliderCell *)cell {

    if (_canSeek) {
        
        __unsafe_unretained typeof(self) obj = self;
        double value = cell.doubleValue;
        
        dispatch_async(_seek_queue, ^{
            obj->_player.timePosition = value;
        });
        
        _canSeek = NO;
    }
}

#pragma mark - dispatch source timer handler

static void timer_handler(void *ctx) {
    __unsafe_unretained SLHPlayerViewController *obj = (__bridge id)ctx;
    obj.currentPosition = obj->_player.timePosition;
}

@end
