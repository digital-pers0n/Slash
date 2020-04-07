//
//  SLHTrimViewController.m
//  Slash
//
//  Created by Terminator on 2020/03/23.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLHTrimViewController.h"
#import "SLHTrimView.h"
#import "SLHEncoderItem.h"
#import "SLHTimeFormatter.h"
#import "SLHVideoTrackView.h"
#import "SLHTimelineView.h"
#import "slh_video_frame_extractor.h"

#import "MPVPlayer.h"
#import "MPVPlayerItem.h"
#import "MPVPlayerItemTrack.h"

@interface SLHTrimViewController () <SLHTrimViewDelegate> {
    CGFloat _trimViewWidth;
    __weak IBOutlet SLHTrimView *_trimView;
    __weak IBOutlet NSView *_timelineView;
    __weak IBOutlet NSTextField *_outNameTextField;
    __weak IBOutlet NSView *_trimViewContentView;
    
    SLHVideoTrackView *_videoTrackView;
    
    BOOL _shouldDisplayPreviewImages;
    CGFloat _verticalZoom;
    CGFloat _horizontalZoom;
    struct _trimViewFlags {
        unsigned int needsUpdateStartValue:1;
        unsigned int shouldStop:1;
    } _TVFlags;
}

@property (nonatomic) BOOL busy;

@end

@implementation SLHTrimViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _verticalZoom = 0.5;
        _horizontalZoom = 3.0;
    }
    return self;
}

- (NSNibName)nibName {
    return self.className;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _trimView.formatter = [SLHTimeFormatter sharedFormatter];
    
    NSRect frame = NSInsetRect(_trimView.frame, 10, 2);
    _videoTrackView = [[SLHVideoTrackView alloc] initWithFrame:frame];
    _videoTrackView.autoresizingMask = _trimView.autoresizingMask;
    
    [_trimView.superview addSubview:_videoTrackView
               positioned:NSWindowBelow
               relativeTo:_trimView];
    
    if (!_shouldDisplayPreviewImages) {
        _trimView.style = SLHTrimViewStyleSimple;
        _videoTrackView.hidden = YES;
    }
    
    // re-apply zoom mulitpliers
    self.verticalZoom = _verticalZoom;
    self.horizontalZoom = _horizontalZoom;
}

#pragma mark - Properties

- (void)setVerticalZoom:(CGFloat)verticalZoom {
    NSView *view = _trimViewContentView;
    NSRect frame = view.frame;
    CGFloat h = round(verticalZoom * (CGFloat)100.0);
    frame.origin.y -= (h - NSHeight(frame)) * (CGFloat)0.5;
    frame.size.height = h;
    view.frame = frame;
    _verticalZoom = verticalZoom;
}

- (void)setHorizontalZoom:(CGFloat)horizontalZoom {
    NSView *view = _timelineView;
    NSRect frame = view.frame;
    frame.size.width = round(horizontalZoom * (CGFloat)200.0);
    view.frame = frame;
    _horizontalZoom = horizontalZoom;
}

- (void)setShouldDisplayPreviewImages:(BOOL)value {
    if (_shouldDisplayPreviewImages == value) { return; }
    if (value) {
        _videoTrackView.hidden = NO;
        if (_encoderItem) {
            [self displayPreviewsIfCan:_encoderItem];
        }
        _trimView.style = SLHTrimViewStyleFrame;
    } else {
        _videoTrackView.videoFrameImages = nil;
        _videoTrackView.hidden = YES;
        _trimView.style = SLHTrimViewStyleSimple;
    }
    _shouldDisplayPreviewImages = value;
    _trimView.needsDisplay = YES;
}

- (void)setEncoderItem:(SLHEncoderItem *)encoderItem {
    if (encoderItem == _encoderItem) { return; }
    if (encoderItem) {
        
        _trimView.maxValue = encoderItem.playerItem.duration;
        _trimView.endValue = encoderItem.intervalEnd;
        _trimView.startValue = encoderItem.intervalStart;
        
        [_trimView bind:@"endValue"
               toObject:encoderItem
            withKeyPath:@"intervalEnd"
                options:nil];
        
        [_trimView bind:@"startValue"
               toObject:encoderItem
            withKeyPath:@"intervalStart"
                options:nil];
        
        [_outNameTextField bind:NSValueBinding
                       toObject:encoderItem
                    withKeyPath:@"outputFileName"
                        options:nil];
        
        [_outNameTextField bind:NSToolTipBinding
                       toObject:encoderItem
                    withKeyPath:@"outputPath"
                        options:nil];
        
        if (_shouldDisplayPreviewImages) {
            [self displayPreviewsIfCan:encoderItem];
        } else {
            [self updateVideoTrackView:nil];
        }
    } else {
        [_trimView unbind:@"endValue"];
        [_trimView unbind:@"startValue"];
        [_outNameTextField unbind:NSValueBinding];
        [_outNameTextField unbind:NSToolTipBinding];
    }
    _encoderItem = encoderItem;
}

- (void)displayPreviewsIfCan:(SLHEncoderItem *)encoderItem {
    if (encoderItem.previewImages) {
        [self updateVideoTrackView:encoderItem.previewImages];
    } else {
        MPVPlayerItem *playerItem = encoderItem.playerItem;
        if (playerItem.hasVideoStreams &&
            playerItem.bestVideoTrack.averageFrameRate > 0)
        {
            [self generatePreviews:encoderItem];
        }
    }
}

- (void)generatePreviews:(SLHEncoderItem *)encoderItem {
    self.busy = YES;
    __unsafe_unretained typeof(self) uSelf = self;
    [encoderItem generatePreviewImagesWithBlock:^(BOOL success) {
        NSArray * result = encoderItem.previewImages;
        SLHTrimViewStyle style = (success) ? SLHTrimViewStyleFrame : SLHTrimViewStyleSimple;
        CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^{
            [uSelf updateVideoTrackView:result];
            uSelf->_trimView.style = style;
            self.busy = NO;
        });

    }];
}

- (void)updateVideoTrackView:(NSArray *)images {
    SLHVideoTrackView * vtView = _videoTrackView;
    vtView.videoFrameImages = images;
    vtView.needsDisplay = YES;
}

#pragma mark - MPVPlayer Notifications

- (void)playerDidRestartPlayback:(NSNotification *)n {
    
    if (_TVFlags.shouldStop) {
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        [nc removeObserver:self
                      name:MPVPlayerDidStartSeekNotification
                    object:_player];
        
        [nc removeObserver:self
                      name:MPVPlayerDidRestartPlaybackNotification
                    object:_player];
        
        if (_TVFlags.needsUpdateStartValue) {
            _encoderItem.intervalStart = _player.timePosition;
            
        } else {
            _encoderItem.intervalEnd = _player.timePosition;
        }
        _TVFlags.shouldStop = 0;
        return;
    }
    
    double time = 0;
    if (_TVFlags.needsUpdateStartValue) {
        time = _encoderItem.interval.start;
    } else {
        time = _encoderItem.interval.end;
    }
    _player.timePosition = time;
}

#pragma mark - SLHTrimViewDelegate

- (void)trimViewMouseDown:(SLHTrimView *)trimView {
    
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver:self
           selector:@selector(playerDidRestartPlayback:)
               name:MPVPlayerDidRestartPlaybackNotification
             object:_player];
    
}

- (void)trimViewMouseDownStartPosition:(SLHTrimView *)trimView {
    _TVFlags.needsUpdateStartValue = 1;
    _player.timePosition = trimView.startValue;
}

- (void)trimViewMouseDownEndPosition:(SLHTrimView *)trimView {
    _TVFlags.needsUpdateStartValue = 0;
    _player.timePosition = trimView.endValue;
}

- (void)trimViewMouseDraggedStartPosition:(SLHTrimView *)trimView {}

- (void)trimViewMouseDraggedEndPosition:(SLHTrimView *)trimView {}

- (void)trimViewMouseUp:(SLHTrimView *)trimView {
    if (_TVFlags.needsUpdateStartValue) {
        _player.timePosition = trimView.startValue;
    } else {
        _player.timePosition = trimView.endValue;
    }
    _TVFlags.shouldStop = 1;
}

@end