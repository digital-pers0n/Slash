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

- (IBAction)zoom:(id)sender {
}

- (IBAction)preview:(id)sender {
}

- (IBAction)reloadFrame:(id)sender {
    [self _extractFrame];
}

#pragma mark - Properties

- (void)setEncoderItem:(SLHEncoderItem *)encoderItem {
    _encoderItem = encoderItem;
    self.startTime = _encoderItem.interval.start;
    [self _extractFrame];
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
