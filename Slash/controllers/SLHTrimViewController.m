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
#import "SLHPreferences.h"
#import "slh_video_frame_extractor.h"

#import "MPVPlayer.h"
#import "MPVPlayerItem.h"
#import "MPVPlayerItemTrack.h"

@interface SLHTrimViewController () <SLHTrimViewDelegate, SLHTimelineViewDelegate> {
    CGFloat _trimViewWidth;
    __weak IBOutlet SLHTrimView *_trimView;
    __weak IBOutlet SLHTimelineView *_timelineView;
    __weak IBOutlet NSView *_trimViewContentView;
    
    SLHVideoTrackView *_videoTrackView;
    
    BOOL _shouldDisplayPreviewImages;
    CGFloat _verticalZoom;
    CGFloat _horizontalZoom;
    struct _trimViewFlags {
        unsigned int needsUpdateStartValue:1;
        unsigned int shouldStop:1;
        unsigned int shouldResumePlayback:1;
    } _TVFlags;
}

@property (nonatomic) BOOL busy;
@property (nonatomic, weak, nullable) SLHEncoderItem *encoderItem;

@end

@implementation SLHTrimViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self loadPreferences];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_itemsArrayController removeObserver:self
                               forKeyPath:@"selection"
                                  context:&SLHTrimViewControllerKVOContext];
    [self savePreferences];
}

- (NSNibName)nibName {
    return self.className;
}

- (void)loadPreferences {
    SLHPreferences * prefs = [SLHPreferences preferences];
    _shouldDisplayPreviewImages = prefs.trimViewShouldGeneratePreviewImages;
    
    double value;
    value = prefs.trimViewVerticalZoom;
    _verticalZoom = (value) ? value : 0.5;
    
    value = prefs.trimViewHorizontalZoom;
    _horizontalZoom = (value) ? value : 3.0;
}

- (void)savePreferences {
    SLHPreferences * prefs = [SLHPreferences preferences];
    prefs.trimViewShouldGeneratePreviewImages = _shouldDisplayPreviewImages;
    prefs.trimViewVerticalZoom = _verticalZoom;
    prefs.trimViewHorizontalZoom = _horizontalZoom;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _timelineView.indicatorMargin = SLHTrimViewHandleThickness + 5;
    
    SLHTrimView *trimView = _trimView;
    trimView.formatter = [SLHTimeFormatter sharedFormatter];
    
    NSRect frame = NSInsetRect(trimView.frame, SLHTrimViewHandleThickness, 2);
    _videoTrackView = [[SLHVideoTrackView alloc] initWithFrame:frame];
    _videoTrackView.autoresizingMask = trimView.autoresizingMask;
    _videoTrackView.wantsLayer = YES;
    
    [trimView.superview addSubview:_videoTrackView
               positioned:NSWindowBelow
               relativeTo:trimView];
    
    if (!_shouldDisplayPreviewImages) {
        trimView.style = SLHTrimViewStyleSimple;
        _videoTrackView.hidden = YES;
    }
    
    // re-apply zoom mulitpliers
    self.verticalZoom = _verticalZoom;
    self.horizontalZoom = _horizontalZoom;
    
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(applicationWillTerminate:)
               name:NSApplicationWillTerminateNotification
             object:NSApp];
}

#pragma mark - IBAction

- (IBAction)magnify:(NSMagnificationGestureRecognizer *)sender {
    const CGFloat scale = _horizontalZoom + sender.magnification;
    if (scale > 1.0 && scale < 30.0) {
        self.horizontalZoom = scale;
    }
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
    frame.size.width = round(horizontalZoom * (CGFloat)300.0);
    view.frame = frame;
    _horizontalZoom = horizontalZoom;
}

- (void)setShouldDisplayPreviewImages:(BOOL)value {
    if (_shouldDisplayPreviewImages == value) { return; }
    SLHEncoderItem *encoderItem = _encoderItem;
    SLHTrimView *trimView = _trimView;
    if (value) {
        _videoTrackView.hidden = NO;
        if (encoderItem) {
            [self displayPreviewsIfCan:encoderItem];
        }
        trimView.style = SLHTrimViewStyleFrame;
    } else {
        _videoTrackView.videoFrameImages = nil;
        _videoTrackView.hidden = YES;
        trimView.style = SLHTrimViewStyleSimple;
    }
    _shouldDisplayPreviewImages = value;
    trimView.needsDisplay = YES;
}

- (void)setEncoderItem:(SLHEncoderItem *)encoderItem {
    if (encoderItem == _encoderItem) { return; }
    SLHTrimView *trimView = _trimView;
    if (encoderItem) {
        double maxValue = encoderItem.playerItem.duration;
        _timelineView.maxValue = maxValue;
        [trimView reset];
        trimView.maxValue = maxValue;
        trimView.endValue = encoderItem.intervalEnd;
        trimView.startValue = encoderItem.intervalStart;
        
        [trimView bind:@"endValue"
               toObject:encoderItem
            withKeyPath:@"intervalEnd"
                options:nil];
        
        [trimView bind:@"startValue"
               toObject:encoderItem
            withKeyPath:@"intervalStart"
                options:nil];
        
        if (_shouldDisplayPreviewImages) {
            [self displayPreviewsIfCan:encoderItem];
        } else {
            [self updateVideoTrackView:nil];
        }
    } else {
        [trimView unbind:@"endValue"];
        [trimView unbind:@"startValue"];
    }
    _encoderItem = encoderItem;
}

- (void)setItemsArrayController:(NSArrayController *)newController {
    NSArrayController *itemsArrayController = _itemsArrayController;
    if (itemsArrayController == newController) { return; }
    if (itemsArrayController) {
        [itemsArrayController removeObserver:self
                                  forKeyPath:@"selection"
                                     context:&SLHTrimViewControllerKVOContext];
    }
    if (newController) {
        [newController addObserver:self
                        forKeyPath:@"selection"
                           options:NSKeyValueObservingOptionNew
                           context:&SLHTrimViewControllerKVOContext];
    }
    _itemsArrayController = newController;
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
        } else {
            [self updateVideoTrackView:nil];
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
            uSelf.busy = NO;
        });

    }];
}

- (void)updateVideoTrackView:(NSArray *)images {
    SLHVideoTrackView * vtView = _videoTrackView;
    vtView.videoFrameImages = images;
    vtView.needsDisplay = YES;
}

#pragma mark - Methods

- (void)goToCurrentPlaybackPosition {
    SLHTimelineView *timelineView = _timelineView;
    NSScrollView *scrollView = timelineView.enclosingScrollView;
    NSClipView *clipView = scrollView.contentView;
    const CGFloat position = _player.timePosition;
    const CGFloat contentWidth = NSWidth(clipView.frame);
  
    NSRect trackRect = timelineView.frame;
    
    CGFloat scale = (position - timelineView.minValue) /
                    (timelineView.maxValue - timelineView.minValue);
    
    CGFloat origin = floor((NSWidth(trackRect)) * scale);
    
    NSPoint pt = NSMakePoint(floor(origin - contentWidth * 0.5), 0);
    [clipView scrollToPoint:pt];
    [scrollView reflectScrolledClipView:clipView];
    timelineView.doubleValue = position;
    timelineView.needsDisplay = YES;
}

- (void)goToSelectionStart {
    NSScrollView * scrollView = _timelineView.enclosingScrollView;
    NSClipView * clipView = scrollView.contentView;
    const NSRect selection = _trimView.selectionFrame;
    const CGFloat contentWidth = NSWidth(clipView.frame);
    
    NSPoint pt = NSMakePoint(floor(NSMinX(selection) - contentWidth * 0.5), 0);
    [clipView scrollToPoint:pt];
    [scrollView reflectScrolledClipView:clipView];
}

- (void)goToSelectionEnd {
    NSScrollView * scrollView = _timelineView.enclosingScrollView;
    NSClipView * clipView = scrollView.contentView;
    const NSRect selection = _trimView.selectionFrame;
    const CGFloat contentWidth = NSWidth(clipView.frame);

    NSPoint pt = NSMakePoint(floor(NSMaxX(selection) - contentWidth * 0.5), 0);
    [clipView scrollToPoint:pt];
    [scrollView reflectScrolledClipView:clipView];
}

- (void)goToStart {
    SLHTimelineView *timelineView = _timelineView;
    NSScrollView * scrollView = timelineView.enclosingScrollView;
    NSClipView * clipView = scrollView.contentView;
    const CGFloat cvWidth = NSWidth(clipView.frame);
    const CGFloat tvWidth = NSWidth(timelineView.frame);
    if (tvWidth > cvWidth) {
        [clipView scrollToPoint:NSZeroPoint];
        [scrollView reflectScrolledClipView:clipView];
    }
}

- (void)goToEnd {
    SLHTimelineView *timelineView = _timelineView;
    NSScrollView * scrollView = timelineView.enclosingScrollView;
    NSClipView * clipView = scrollView.contentView;
    const CGFloat cvWidth = NSWidth(clipView.frame);
    const CGFloat tvWidth = NSWidth(timelineView.frame);
    if (tvWidth > cvWidth) {
        NSPoint pt = NSMakePoint(tvWidth - cvWidth, 0);
        [clipView scrollToPoint:pt];
        [scrollView reflectScrolledClipView:clipView];
    }
}

- (void)pauseIfNeeded {
    MPVPlayer *player = _player;
    if ([player isPaused]) {
        _TVFlags.shouldResumePlayback = 0;
    } else {
        [player pause];
        _TVFlags.shouldResumePlayback = 1;
    }
}

#pragma mark - KVO
static char SLHTrimViewControllerKVOContext;

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == &SLHTrimViewControllerKVOContext) {
        self.encoderItem = _itemsArrayController.selectedObjects.firstObject;
    } else {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}

#pragma mark - MPVPlayer Notifications

- (void)playerDidRestartPlayback:(NSNotification *)n {
    MPVPlayer *player = _player;
    SLHEncoderItem *encoderItem = _encoderItem;
    if (_TVFlags.shouldStop) {
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        
        [nc removeObserver:self
                      name:MPVPlayerDidRestartPlaybackNotification
                    object:player];
        
        if (_TVFlags.needsUpdateStartValue) {
            encoderItem.intervalStart = player.timePosition;
            
        } else {
            encoderItem.intervalEnd = player.timePosition;
        }
        
        if (_TVFlags.shouldResumePlayback) {
            [player play];
        }
        
        return;
    }
    
    double time = 0;
    if (_TVFlags.needsUpdateStartValue) {
        time = encoderItem.interval.start;
    } else {
        time = encoderItem.interval.end;
    }
    player.timePosition = time;
}

- (void)updatePlayerTimePostion:(NSNotification *)n {
    MPVPlayer *player = _player;
    if (_TVFlags.shouldStop) {
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        
        [nc removeObserver:self
                      name:MPVPlayerDidRestartPlaybackNotification
                    object:player];
        
        if (_TVFlags.shouldResumePlayback) {
            [player play];
        }

    } else {
        player.timePosition = _timelineView.doubleValue;
    }
}

#pragma mark - SLHTrimViewDelegate

- (void)trimViewMouseDown:(SLHTrimView *)trimView {
    _TVFlags.shouldStop = 0;
    
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver:self
           selector:@selector(playerDidRestartPlayback:)
               name:MPVPlayerDidRestartPlaybackNotification
             object:_player];
    
    [self pauseIfNeeded];
}

- (void)trimViewMouseDownStartPosition:(SLHTrimView *)trimView {
    _TVFlags.needsUpdateStartValue = 1;
    _player.timePosition = trimView.startValue;
}

- (void)trimViewMouseDownEndPosition:(SLHTrimView *)trimView {
    _TVFlags.needsUpdateStartValue = 0;
    _player.timePosition = trimView.endValue;
}

- (void)trimViewMouseUp:(SLHTrimView *)trimView {
    MPVPlayer *player = _player;
    if (_TVFlags.needsUpdateStartValue) {
        player.timePosition = trimView.startValue;
    } else {
        player.timePosition = trimView.endValue;
    }
    _TVFlags.shouldStop = 1;
}

#pragma mark - SLHTimelineViewDelegate

- (void)timelineViewMouseDown:(SLHTimelineView *)timelineView {
    _TVFlags.shouldStop = 0;
    MPVPlayer *player = _player;
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver:self
           selector:@selector(updatePlayerTimePostion:)
               name:MPVPlayerDidRestartPlaybackNotification
             object:player];
    player.timePosition = timelineView.doubleValue;
    
    [self pauseIfNeeded];
}

- (void)timelineViewMouseUp:(SLHTimelineView *)timelineView {
    _player.timePosition = timelineView.doubleValue;
    _TVFlags.shouldStop = 1;
}

#pragma mark - Notifications

- (void)applicationWillTerminate:(NSNotification *)n {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self savePreferences];
}

@end
