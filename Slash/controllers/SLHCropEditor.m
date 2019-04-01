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
#import "SLHMediaItem.h"
#import "SLHFilterOptions.h"

extern NSString *const SLHPreferencesFFMpegFilePathKey;

@interface SLHCropEditor () <SLHImageViewDelegate, NSWindowDelegate> {
    
    IBOutlet SLHImageView *_imageView;
    SLHEncoderItem *_encoderItem;
    NSString *_ffmpegPath;
    dispatch_queue_t _bg_queue;
    dispatch_queue_t _main_queue;
    
    BOOL _zoomed;
}

@property double startTime;

@end

@implementation SLHCropEditor

- (NSString *)windowNibName {
    return self.className;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    NSString *ffmpegPath = [[NSUserDefaults standardUserDefaults] objectForKey:SLHPreferencesFFMpegFilePathKey];
    if (!ffmpegPath) {
        ffmpegPath = @"/usr/local/bin/ffmpeg";
    }
    _ffmpegPath = ffmpegPath;
    _bg_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    _main_queue = dispatch_get_main_queue();
    _imageView.currentToolMode = IKToolModeSelect;
}

#pragma mark - IBActions

- (IBAction)xDidChange:(id)sender {
}

- (IBAction)yDidChange:(id)sender {
}

- (IBAction)widthDidChange:(id)sender {
}

- (IBAction)heightDidChange:(id)sender {
}

- (IBAction)detectCropArea:(id)sender {
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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), _main_queue, ^{
        _imageView.selectionRect = rect;

    });
    
}

#pragma mark - Properties

- (void)setEncoderItem:(SLHEncoderItem *)encoderItem {
    _encoderItem = encoderItem;
    self.startTime = _encoderItem.interval.start;
    SLHFilterOptions *options = encoderItem.filters;
    _zoomed = NO;
   _imageView.currentToolMode = IKToolModeNone;
    [self _extractFrame];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), _main_queue, ^{
        NSRect rect = NSMakeRect(options.videoCropX, options.videoCropY, options.videoCropWidth, options.videoCropHeight);
        _imageView.selectionRect = rect;

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
    options.videoCropX = rect.origin.x;
    options.videoCropY = rect.origin.y;
    options.videoCropWidth = rect.size.width;
    options.videoCropHeight = rect.size.height;
}

#pragma mark - Private

static inline void _safeCFRelease(CFTypeRef ref) {
    if (ref) {
        CFRelease(ref);
    }
}

- (void)_extractFrame {
    dispatch_async(_bg_queue, ^{
        char *cmd;
        asprintf(&cmd, "%s -loglevel 0 -ss %.3f -i \"%s\""
                 " -vf \"rotate=PI,hflip\" -vframes 1 -q:v 2 -f image2pipe -",
                 _ffmpegPath.UTF8String, _startTime, _encoderItem.mediaItem.filePath.UTF8String);
        FILE *pipe = popen(cmd, "r");
        const size_t block_length = 4096;
        size_t bytes_total = 0;
        size_t bytes_read = 0;
        char *output = malloc(block_length * sizeof(char));
        while ((bytes_read = fread(output + bytes_total, sizeof(char), block_length, pipe)) > 0) {
            bytes_total += bytes_read;
            char *tmp = realloc(output, bytes_total * sizeof(char) + block_length);
            if (!tmp) {
                exit(EXIT_FAILURE);
            }
            output = tmp;
        }
        CFDataRef cfdata_ref = CFDataCreate(NULL, (UInt8 *)output, bytes_total);
        CGImageSourceRef cfimage_source_ref = CGImageSourceCreateWithData(cfdata_ref, NULL);
        CGImageRef cfimage_ref = CGImageSourceCreateImageAtIndex(cfimage_source_ref, 0, NULL);
        if (cfimage_ref) {
            dispatch_sync(_main_queue, ^{
                [_imageView setImage:cfimage_ref imageProperties:0];
                
                // Rotate and flip the frame because ffmpeg and Cocoa are using different coordinates
                _imageView.rotationAngle = M_PI;
                [_imageView flipImageHorizontal:nil];
                [_imageView zoomImageToFit:nil];
                _imageView.autoresizes = YES;
            });
        } else {
            NSLog(@"%s Error: invalid data", __PRETTY_FUNCTION__);
        }
        free(cmd);
        pclose(pipe);
        free(output);
        _safeCFRelease(cfimage_ref);
        _safeCFRelease(cfimage_source_ref);
        _safeCFRelease(cfdata_ref);
    });
}

@end
