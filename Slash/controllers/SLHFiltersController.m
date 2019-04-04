//
//  SLHFiltersController.m
//  Slash
//
//  Created by Terminator on 2018/11/22.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import "SLHFiltersController.h"
#import "SLHEncoderItem.h"
#import "SLHFilterOptions.h"
#import "SLHCropEditor.h"
#import "SLHMediaItem.h"

extern NSString *const SLHPreferencesMPVFilePathKey;

extern NSString *const SLHEncoderVideoFilterCropKey;
extern NSString *const SLHEncoderVideoFilterDeinterlaceKey;
extern NSString *const SLHEncoderAudioFilterFadeInKey;
extern NSString *const SLHEncoderAudioFilterFadeOutKey;
extern NSString *const SLHEncoderAudioFilterPreampKey;

static NSString *const _videoCropFmt = @"crop=w=%ld:h=%ld:x=%ld:y=%ld";
static NSString *const _audioFadeInFmt = @"afade=t=in:d=%.3f";
static NSString *const _audioFadeOutFmt = @"afade=t=out:d=%.3f:st=%.3f";
static NSString *const _audioPreampFmt = @"acompressor=makeup=%ld";


@interface SLHFiltersController () {
    
    IBOutlet NSTextField *_cropTextField;
    IBOutlet NSTextField *_audioFadeInTextField;
    IBOutlet NSTextField *_audioFadeOutTextField;
    IBOutlet NSTextField *_audioPreampTextField;
    
    SLHEncoderItem *_encoderItem;
    
    IBOutlet SLHCropEditor *_cropEditor;
}

@end

@implementation SLHFiltersController

#pragma mark - Initialization

+ (instancetype)filtersController {
    static dispatch_once_t onceToken;
    static SLHFiltersController *obj = nil;
    dispatch_once(&onceToken, ^{
        obj = [[SLHFiltersController alloc] init];
    });
    return obj;
}

- (NSString *)nibName {
    return self.className;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

#pragma mark - Properties

- (void)setEncoderItem:(SLHEncoderItem *)encoderItem {
    _encoderItem = encoderItem;
    if (_cropEditor.hasWindow && _encoderItem) {
        _cropEditor.encoderItem = encoderItem;
    }
}

- (SLHEncoderItem *)encoderItem {
    return _encoderItem;
}

#pragma mark - IBActions

- (IBAction)previewCropArea:(id)sender {
    SLHFilterOptions *options = _encoderItem.filters;
    NSRect r = NSMakeRect(options.videoCropX, options.videoCropY, options.videoCropWidth, options.videoCropHeight);
;
    if ((r.size.height <= 0) || (r.size.width <= 0)) {
        NSBeep();
        return;
    }
    NSString *path = [[NSUserDefaults standardUserDefaults] objectForKey:SLHPreferencesMPVFilePathKey];
    if (!path) {
        path = @"/usr/local/bin/mpv";
    }
    char *cmd;
    asprintf(&cmd,
             "%s --no-terminal --loop=yes --osd-fractions --osd-level=3 "
             " -vf=lavfi=[crop=%.0f:%.0f:%.0f:%.0f] --start=+%.3f \"%s\" &",
             path.UTF8String, r.size.width, r.size.height, r.origin.x, r.origin.y, _encoderItem.interval.start, _encoderItem.mediaItem.filePath.UTF8String);
    system(cmd);
    free(cmd);
}

- (IBAction)detectCropArea:(id)sender {
    if (!_encoderItem) {
        NSBeep();
        return;
    }
    NSRect rect = [SLHCropEditor cropRectForItem:_encoderItem];
    SLHFilterOptions *options = _encoderItem.filters;
    options.videoCropX = rect.origin.x;
    options.videoCropY = rect.origin.y;
    options.videoCropWidth = rect.size.width;
    options.videoCropHeight = rect.size.height;
}

- (IBAction)cropEditorButtonAction:(id)sender {
    if (!_encoderItem) {
        NSBeep();
        return;
    }
    [_cropEditor showWindow:sender];
    _cropEditor.encoderItem = _encoderItem;
}


@end
