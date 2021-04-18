//
//  SLHCropEditor.m
//  Slash
//
//  Created by Terminator on 2019/03/26.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHCropEditor.h"
#import "SLHImageView.h"
#import "SLHEncoderItem.h"
#import "SLHFilterOptions.h"
#import "SLHPreferences.h"
#import "SLHSliderCell.h"
#import "SLHVideoSlider.h"
#import "slh_video_frame_extractor.h"

#import "SLTRemotePlayer.h"

#import "MPVPlayerItem.h"
#import "MPVPlayerItemTrack.h"

@interface SLHCropEditor () <SLHImageViewDelegate, NSWindowDelegate, SLHSliderCellMouseTrackingDelegate, SLHVideoSliderDelegate> {
    
    IBOutlet SLHImageView *_imageView;
    SLHEncoderItem *_encoderItem;
    SLHPreferences *_preferences;
    dispatch_queue_t _bg_queue;
    dispatch_queue_t _main_queue;
    
    BOOL _zoomed;
    BOOL _busy;
}

@property double startTime;

@end

@implementation SLHCropEditor

static NSRect getCropRect(const char *ffmpeg, double startTime,
                          const char *filePath)
{
    NSRect r = { 0 };
    char *cmd;
    asprintf(&cmd, "%s -ss %.3f -i \"%s\" -vf cropdetect -t 3 -f null - 2>&1"
             " | awk '/crop/ { print $NF }' | tail -1",
             ffmpeg, startTime, filePath);
    FILE *pipe = popen(cmd, "r");
    const int len = 64;
    char str[len];
    if (fgets(str, len, pipe)) {
        char *start = strchr(str, '=');
        char *end = strchr(str, ':');
        long result[4] = { 0, 0, 0, 0 };
        _get_coordinates(++start, end, 0, result);
        r = NSMakeRect(result[2], result[3], result[0], result[1]);
    }
    free(cmd);
    pclose(pipe);
    return r;
}

+ (NSRect)cropRectForItem:(SLHEncoderItem *)item {
    SLHPreferences *prefs = SLHPreferences.preferences;
    NSRect r = { 0 };
    if (!prefs.hasFFmpeg) return r;
    
    NSString *path = prefs.ffmpegPath;
    MPVPlayerItem *playerItem = item.playerItem;
    r = getCropRect(path.UTF8String, item.interval.start,
                    playerItem.url.fileSystemRepresentation);
    NSInteger idx = item.videoStreamIndex;
    if (idx > -1) {
        r.origin.y = playerItem.tracks[idx].videoSize.height - NSHeight(r) - NSMinY(r);
    }
    return r;
}

- (NSString *)windowNibName {
    return self.className;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    _preferences = SLHPreferences.preferences;
    _bg_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    _main_queue = dispatch_get_main_queue();
    _imageView.currentToolMode = IKToolModeSelect;
}

#pragma mark - SLHVideoSliderDelegate

- (void)videoSlider:(SLHVideoSlider *)slider scrollWheelDeltaY:(double)deltaY {
    double candidate = _startTime + (-deltaY);
    if (candidate >= 0 && candidate <= _encoderItem.playerItem.duration) {
        self.startTime = candidate;
        [self reloadFrame:nil];
    }
}

#pragma mark - SLHSliderCellMouseTrackingDelegate 

- (void)sliderCellMouseUp:(SLHSliderCell *)cell {

    [self reloadFrame:nil];
}

- (void)sliderCellMouseDown:(SLHSliderCell *)cell { }

- (void)sliderCellMouseDragged:(SLHSliderCell *)cell { }

#pragma mark - IBActions

- (IBAction)xDidChange:(id)sender {
    NSRect r = _imageView.selectionRect;
    r.origin.x = _encoderItem.filters.videoCropX;
    _imageView.selectionRect = r;
}

- (IBAction)yDidChange:(id)sender {
    NSRect r = _imageView.selectionRect;
    r.origin.y = _encoderItem.filters.videoCropY;
    _imageView.selectionRect = r;
}

- (IBAction)widthDidChange:(id)sender {
    NSRect r = _imageView.selectionRect;
    r.size.width = _encoderItem.filters.videoCropWidth;
    _imageView.selectionRect = r;
}

- (IBAction)heightDidChange:(id)sender {
    NSRect r = _imageView.selectionRect;
    r.size.height = _encoderItem.filters.videoCropHeight;
    _imageView.selectionRect = r;
}

- (NSRect)cropArea {
    NSRect r = NSZeroRect;
    NSString *ffmpegPath = _preferences.ffmpegPath;
    MPVPlayerItem *playerItem = _encoderItem.playerItem;
    r = getCropRect(ffmpegPath.UTF8String, _encoderItem.interval.start,
                    playerItem.url.fileSystemRepresentation);
    NSInteger idx = _encoderItem.videoStreamIndex;
    if (idx > -1) {
        r.origin.y = playerItem.tracks[idx].videoSize.height - NSHeight(r) - NSMinY(r);
    }
    
    return r;
}

- (IBAction)detectCropArea:(NSButton *)sender {
    sender.enabled = NO;
     __unsafe_unretained typeof(self) obj = self;
    dispatch_async(_bg_queue, ^{
        NSRect rect = [obj cropArea];
        dispatch_async(obj->_main_queue, ^{
            SLHFilterOptions *options = obj->_encoderItem.filters;
            options.videoCropRect = rect;
            sender.enabled = YES;
            obj->_imageView.selectionRect = rect;
        });
    });
}

- (IBAction)zoom:(NSButton *)sender {
    NSRect rect = _imageView.selectionRect;
    if (_zoomed) {
        [_imageView zoomImageToFit:nil];
        _zoomed = NO;
        _imageView.autoresizes = YES;
        sender.image = [NSImage imageNamed:NSImageNameEnterFullScreenTemplate];
    } else {
        [_imageView zoomImageToActualSize:nil];
        _zoomed = YES;
        sender.image = [NSImage imageNamed:NSImageNameExitFullScreenTemplate];
    }
    _imageView.selectionRect = rect;
}

- (IBAction)preview:(id)sender {
    NSRect r = _imageView.selectionRect;

    SLTRemotePlayer *player = SLTRemotePlayer.sharedInstance;
    player.url = _encoderItem.playerItem.url;
    if (player.error) {
        NSBeep();
        [self presentError:player.error];
        return;
    }

    [player setVideoFilter:[NSString stringWithFormat:@"lavfi=[crop=w=%.0f:h=%.0f:x=%.0f:y=%.0f]",
                            NSWidth(r), NSHeight(r), NSMinX(r), _imageView.imageSize.height - NSHeight(r) - NSMinY(r)]];
    [player seekTo:_startTime];
    [player orderFront];
 
}

// Problems (Tested under macOS 10.11)
// When the IKImageView.currentToolMode property is set to IKToolModeSelect and a new image is loaded :
// 1. The coordinates of the selection layer are all messed up.
//    The layer doesn't auto scale with the view. The selection rect doesn't appear under the mouse pointer.
//
// 2. The IKImageView setImage:imageProperties: method crashes the application.
//
// Solution
// Assign the IKImageView.currentToolMode property to IKToolModeNone before loading a new image

- (IBAction)reloadFrame:(id)sender {
    _zoomed = NO;
    NSRect rect = _imageView.selectionRect;
    _imageView.currentToolMode = IKToolModeNone;
    [self _extractFrame];
    __unsafe_unretained typeof(self) obj = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), _main_queue, ^{
        obj->_imageView.selectionRect = rect;

    });
}

- (IBAction)reselect:(id)sender {
    NSRect rect = _encoderItem.filters.videoCropRect;
    _imageView.selectionRect = rect;
}

#pragma mark - Properties

- (void)setEncoderItem:(SLHEncoderItem *)encoderItem {
    _imageView.currentToolMode = IKToolModeNone;
    _encoderItem = encoderItem;
    self.startTime = _encoderItem.interval.start;
    SLHFilterOptions *options = encoderItem.filters;
    _zoomed = NO;
    [self _extractFrame];
     __unsafe_unretained typeof(self) obj = self;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), _main_queue, ^{
            obj->_imageView.selectionRect = options.videoCropRect;
    });

}

- (SLHEncoderItem *)encoderItem {
    return _encoderItem;
}

#pragma mark - NSWindowDelegate

- (void)windowDidBecomeMain:(NSNotification *)notification {
    _hasWindow = YES;
}

- (void)windowWillClose:(NSNotification *)notification {
    _hasWindow = NO;
}

#pragma mark - SLHImageViewDelegate

- (void)imageView:(SLHImageView *)view didUpdateSelection:(NSRect)rect {
    SLHFilterOptions *options = _encoderItem.filters;
    options.videoCropRect = rect;
}

#pragma mark - Private

/**
 Extract coordinates from a char array and store them in the result array.
 
 @param result - [0] - width, [1] - height, [2] - x, [3] - y
 */
static void _get_coordinates(char *start, char *end, int n, long *result) {
    char value[6];
    int i = 0;
    while (start < end) {
        value[i] = *start;
        start++;
        i++;
    }
    long r = atol(value);
    result[n] = r;
    n++;
    start++;
    end = strchr(start, ':');
    if (!end) {
        r = atol(start);
        result[n] = r;
        return;
    }
    _get_coordinates(start, end, n, result);
}

- (void)_extractFrame {
    if (_busy) { return; }
    _busy = YES;
    __unsafe_unretained typeof(self) uSelf = self;
    NSString *ffmpegPath = _preferences.ffmpegPath;
    MPVPlayerItem *playerItem = _encoderItem.playerItem;
    NSURL *url = playerItem.url;
    double timePos = _startTime;
    NSSize size = playerItem.bestVideoTrack.videoSize;
    dispatch_async(_bg_queue, ^{
        CGImageRef image = nil;
        vfe_get_image(ffmpegPath.fileSystemRepresentation,
                      timePos, size, url.fileSystemRepresentation, &image);
        if (image) {
            CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^{
                [uSelf->_imageView setImage:image imageProperties:0];
                uSelf->_imageView.autoresizes = YES;
                CFRelease(image);
                uSelf->_busy = NO;
            });
        } else {
           CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^{
               uSelf->_busy = NO;
           });
        }
    });
}

@end
