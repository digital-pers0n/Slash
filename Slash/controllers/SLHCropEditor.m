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

@interface SLHCropEditor () <SLHImageViewDelegate> {
    
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
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
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

@end
