//
//  SLHPlayerViewInlineController.m
//  Slash
//
//  Created by Terminator on 2019/10/16.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHPlayerViewController.h"
#import "SLHSliderCell.h"
#import "SLHPreferences.h"
#import "SLHVideoSlider.h"

#import "MPVPlayer.h"
#import "MPVPlayerItem.h"
#import "MPVPlayerItemTrack.h"
#import "MPVPlayerProperties.h"
#import "MPVPlayerCommands.h"

#define ENABLE_NO_SELECTED_STREAMS_FIX 1

#define bindObject(obj, value, keyPath) [obj bind:value toObject:self withKeyPath:@#keyPath options:nil]

typedef NS_ENUM(NSUInteger, SLHVolumeIcon) {
    SLHVolumeIconMax,
    SLHVolumeIconMid,
    SLHVolumeIconMin,
    SLHVolumeIconMute
};

@interface SLHPlayerViewController () <MPVPropertyObserving, NSControlTextEditingDelegate, SLHSliderCellMouseTrackingDelegate, SLHVideoSliderDelegate> {
    MPVPlayer *_player;
    double _currentPosition;
    IBOutlet NSTextField *_textField;
    IBOutlet NSSlider *_seekBar;
    IBOutlet NSPopover *_volumePopover;
    IBOutlet NSView *_noVideoView;
    
    BOOL _canSeek;
    BOOL _hasABLoop;
    BOOL _isAudioMuted;
    
    NSArray *_volumeButtonIcons;
    SLHVolumeIcon _currentVolumeIcon;
    
    dispatch_queue_t _bg_queue;
    dispatch_queue_t _timer_queue;
    dispatch_source_t _timer;
    
    CFRunLoopRef _main_runloop;
}

@property (nonatomic) double duration;
@property (nonatomic) double currentPosition;
@property (nonatomic) BOOL seekable;
@property (nonatomic) BOOL hasABLoop;
@property (nonatomic) BOOL hasAudio;
@property (nonatomic) NSImage *volumeButtonIcon;
@property (nonatomic) NSInteger volume;
@property (nonatomic) NSNotificationCenter *notificationCenter;

@property (nonatomic) NSString *noVideoMessage;

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

- (void)resetInOutMarks {
    self.inMark = 0;
    self.outMark = 0;
    if (_hasABLoop) {
        [_player setString:@"no" forProperty:MPVPlayerPropertyABLoopA];
        self.hasABLoop = NO;
    }
}

- (void)loopPlaybackWithStart:(double)inMark end:(double)outMark {
    self.inMark = inMark;
    self.outMark = outMark;
    [_player setDouble:_inMark forProperty:MPVPlayerPropertyABLoopA];
    [_player setDouble:_outMark forProperty:MPVPlayerPropertyABLoopB];
    _player.timePosition = inMark;
    self.hasABLoop = YES;
    
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
    [nc addObserver:self selector:@selector(playerVideoDidChange:) name:MPVPlayerVideoDidChangeNotification object:player];
    [nc addObserver:self selector:@selector(playerDidEnterIdleMode:) name:MPVPlayerDidEnterIdleModeNotification object:player];
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
    _main_runloop = CFRunLoopGetMain();
    _timer_queue = dispatch_get_main_queue();
    
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(
                                                                         DISPATCH_QUEUE_SERIAL,
                                                                         QOS_CLASS_USER_INTERACTIVE, 0);
    _bg_queue = dispatch_queue_create("com.home.MPVOpenGLView.render-queue", attr);

    bindObject(_textField, NSValueBinding, self.currentPosition);
    bindObject(_seekBar, NSValueBinding, self.currentPosition);
    bindObject(_textField, NSEnabledBinding, self.seekable);
    bindObject(_seekBar, NSEnabledBinding, self.seekable);
    SLHSliderCell *sliderCell = _seekBar.cell;
    
    sliderCell.delegate = self;
    bindObject(sliderCell, @"inMark", self.inMark);
    bindObject(sliderCell, @"outMark", self.outMark);
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
    
    double inMark =  _player.timePosition;
    
    if (inMark > _outMark) {
        self.outMark = _player.currentItem.duration;
        [_notificationCenter postNotificationName:SLHPlayerViewControllerDidChangeOutMarkNotification object:self userInfo:nil];
    }
    
    self.inMark = inMark;
    [_notificationCenter postNotificationName:SLHPlayerViewControllerDidChangeInMarkNotification object:self userInfo:nil];
    
    _seekBar.needsDisplay = YES;
}

- (IBAction)outMark:(id)sender {
    
    double outMark = _player.timePosition;
    
    if (outMark < _inMark) {
        self.inMark = 0;
        [_notificationCenter postNotificationName:SLHPlayerViewControllerDidChangeInMarkNotification object:self userInfo:nil];
    }
    
    self.outMark = outMark;
    [_notificationCenter postNotificationName:SLHPlayerViewControllerDidChangeOutMarkNotification object:self userInfo:nil];
    

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

- (IBAction)jumpToInMark:(id)sender {
    [_player seekExactTo:_inMark];
}

- (IBAction)jumpToOutMark:(id)sender {
    [_player seekExactTo:_outMark];
}

- (IBAction)commitSelection:(id)sender {
    if (NSApp.currentEvent.modifierFlags & NSEventModifierFlagOption) {
        [self resetInOutMarks];
        _seekBar.needsDisplay = YES;
    } else {
        [_notificationCenter postNotificationName:SLHPlayerViewControllerDidCommitInOutMarksNotification object:self userInfo:nil];
    }
}

- (IBAction)takeScreenShot:(NSButton *)sender {
    
    sender.enabled = NO;
    __weak MPVPlayer *player = _player;
    CFRunLoopRef main_rl = _main_runloop;
    if (NSApp.currentEvent.modifierFlags & NSEventModifierFlagOption) {
        NSSavePanel *panel = [NSSavePanel savePanel];
        panel.nameFieldStringValue = [_player.currentItem.url.lastPathComponent.stringByDeletingPathExtension stringByAppendingPathExtension:SLHPreferences.preferences.screenshotFormat];
        if ([panel runModal] == NSModalResponseOK) {
            NSURL *url = panel.URL;
            
            dispatch_async(_bg_queue, ^{
                NSError *error = nil;
                if (![player takeScreenshotTo:url includeSubtitles:NO error:&error]) {
                    
                    CFRunLoopPerformBlock(main_rl, kCFRunLoopCommonModes, ^{
                     NSAlert *alert = [NSAlert new];
                     alert.informativeText = error.localizedDescription;
                     alert.messageText = [NSString stringWithFormat:@"Failed to write %@", url.path];
                     [alert runModal];
                 });

                }
                
                CFRunLoopPerformBlock(main_rl, kCFRunLoopCommonModes, ^{
                    sender.enabled = YES;
                });
            });
        }
    } else {
        
        dispatch_async(_bg_queue, ^{
            NSError *error = nil;
            if (![player takeScreenshotError:&error]) {
                
                CFRunLoopPerformBlock(main_rl, kCFRunLoopCommonModes, ^{
                    NSAlert *alert = [NSAlert new];
                    alert.informativeText = error.localizedDescription;
                    alert.messageText = @"Failed to save screenshot.";
                    [alert runModal];
                });
                
            }
            
            CFRunLoopPerformBlock(main_rl, kCFRunLoopCommonModes, ^{
                sender.enabled = YES;
            });
        });
    }
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
    [self resetInOutMarks];
    MPVPlayerItem *item = _player.currentItem;
    BOOL hasAudio = item.hasAudioStreams, hasVideo = item.hasVideoStreams;

    self.hasAudio = hasAudio;
    if (!hasVideo) {
        if (!_noVideoView.superview) {
            
            _videoView.hidden = YES;
            [self.view addSubview:_noVideoView];
            _noVideoView.frame = _videoView.frame;
        }
         self.noVideoMessage = @"No Video";
    } else if (_noVideoView.superview) {
        [_noVideoView removeFromSuperview];
        _videoView.hidden = NO;
    }
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
    if (_canSeek) {
        _player.timePosition = _seekBar.doubleValue;
   }
}

- (void)playerDidStartSeek:(NSNotification *)n {
    self.currentPosition = _player.timePosition;
}

- (void)playerDidEnterIdleMode:(NSNotification *)n {
    
#if ENABLE_NO_SELECTED_STREAMS_FIX
    if (_player.currentItem) {
        
        /* 
           There is a weird bug in the mpv 0.30.0, or maybe it is just my fault.
           Sometimes, after executing the loadfile command, libmpv posts the MPV_EVENT_START_FILE notification, 
           then it prints a strange error that there are no selected video or audio streams and
           immediately enters into the idle-mode without even posting the MPV_EVENT_FILE_LOADED notification. 
           So if the MPVPlayer.currentItem property is not nil, then it can be the bug. 
           Unfortunately, this will break the stop command, if the .currentItem is not nil. 
           Should wait for new mpv releases and recheck.
         */
        
        // reset streams IDs
        [_player setString:@"auto" forProperty:@"vid"];
        [_player setString:@"auto" forProperty:@"aid"];
        [_player setString:@"auto" forProperty:@"sid"];
        
        // reload file
        _player.currentItem = _player.currentItem;
        return;
    }
#endif
    
    if (!_noVideoView.superview) {
       
        _videoView.hidden = YES;
        [self.view addSubview:_noVideoView];
         _noVideoView.frame = _videoView.frame;
    
    }
    self.noVideoMessage = @"Drop a Video File Here";
}

- (void)playerVideoDidChange:(NSNotification *)n {
    NSInteger hasVideo = [_player integerForProperty:MPVPlayerPropertyVideoID];
    if (!hasVideo) {
        if (!_noVideoView.superview) {
            
            _videoView.hidden = YES;
            [self.view addSubview:_noVideoView];
            _noVideoView.frame = _videoView.frame;

        }
        self.noVideoMessage = @"No Video";
    } else {
        if (_noVideoView.superview) {
            [_noVideoView removeFromSuperview];
            _videoView.hidden = NO;
        }
    }
}

#pragma mark - SLHVideoSliderDelegate 

- (void)videoSlider:(SLHVideoSlider *)slider scrollWheelDeltaY:(double)deltaY {
    double candidate = _currentPosition + (-deltaY);
    if (candidate >= 0 && candidate <= _duration) {
        self.currentPosition = candidate;
        _player.timePosition = candidate;
    }
}

#pragma mark - NSControlTextEditingDelegate

- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor {
    [control unbind:NSValueBinding];
    return YES;
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
    _player.timePosition = control.doubleValue;
    bindObject(control, NSValueBinding, self.currentPosition);
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
    bindObject(_seekBar, NSValueBinding, self.currentPosition);
    _canSeek = NO;
}

- (void)sliderCellMouseDown:(SLHSliderCell *)cell {
    _canSeek = YES;
    dispatch_suspend(_timer);
    
    /* At this stage the NSSlider.doubleValue property is always 0 even though NSSlider.objectValue may not be.
       [NSSlider unbind:NSValueBinding] resets the NSSlider.objectValue property to 0,
       but if we bind the self.currentPosition property to @"doubleValue" instead of NSValueBinding,
       then [NSSlider unbind:@"doubleValue"] doesn't reset anything. Maybe it's just a bug.  */
    
    double value = [cell.objectValue doubleValue];
    _player.timePosition = value;

    [_seekBar unbind:NSValueBinding];
    _seekBar.doubleValue = value;
    
    self.currentPosition = value;
}

- (void)sliderCellMouseDragged:(SLHSliderCell *)cell {
    self.currentPosition = cell.doubleValue;
}

#pragma mark - dispatch source timer handler

static void timer_handler(void *ctx) {
    __unsafe_unretained SLHPlayerViewController *obj = (__bridge id)ctx;
    obj.currentPosition = obj->_player.timePosition;
}

@end
