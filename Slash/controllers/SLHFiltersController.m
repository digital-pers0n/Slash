//
//  SLHFiltersController.m
//  Slash
//
//  Created by Terminator on 2018/11/22.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import "SLHFiltersController.h"
#import "SLHEncoderItem.h"
#import "SLHCropEditor.h"

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
    if (_cropEditor.hasWindow) {
        _cropEditor.encoderItem = encoderItem;
    }
}

- (SLHEncoderItem *)encoderItem {
    return _encoderItem;
}

#pragma mark - IBActions

- (IBAction)cropEditorButtonAction:(id)sender {
}


@end
