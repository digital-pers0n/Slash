//
//  SLHFiltersController.m
//  Slash
//
//  Created by Terminator on 2018/11/22.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import "SLHFiltersController.h"
#import "SLHEncoderItem.h"

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
}

@property NSInteger cropVideoX;
@property NSInteger cropVideoY;
@property NSInteger cropVideoWidth;
@property NSInteger cropVideoHeight;
@property BOOL deinterlace;
@property double audioFadeIn;
@property double audioFadeOut;
@property NSInteger audioPreamp;

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
}

- (SLHEncoderItem *)encoderItem {
    
    NSString *key = SLHEncoderVideoFilterCropKey;
    if (_cropVideoWidth || _cropVideoHeight || _cropVideoX || _cropVideoY) {
        _encoderItem.videoFilters[key] =
        [NSString stringWithFormat:_videoCropFmt,
         _cropVideoWidth, _cropVideoHeight, _cropVideoX, _cropVideoY];
    } else {
        [_encoderItem.videoFilters removeObjectForKey:key];
    }
    
    key = SLHEncoderVideoFilterDeinterlaceKey;
    if (_deinterlace) {
        _encoderItem.videoFilters[key] = @"yadiff";
    } else {
        [_encoderItem.videoFilters removeObjectForKey:key];
    }
    
    key = SLHEncoderAudioFilterFadeInKey;
    if (_audioFadeIn) {
        _encoderItem.audioFilters[key] =
        [NSString stringWithFormat:_audioFadeInFmt, _audioFadeIn];
    } else {
        [_encoderItem.audioFilters removeObjectForKey:key];
    }
    
    key = SLHEncoderAudioFilterFadeOutKey;
    if (_audioFadeOut) {
        _encoderItem.audioFilters[key] =
        [NSString stringWithFormat:_audioFadeOutFmt,
         _audioFadeOut, _encoderItem.interval.end - _audioFadeOut];
    } else {
        [_encoderItem.audioFilters removeObjectForKey:key];
    }
    
    key = SLHEncoderAudioFilterPreampKey;
    if (_audioPreamp) {
        _encoderItem.audioFilters[key] =
        [NSString stringWithFormat:_audioPreampFmt, _audioPreamp];
    } else {
        [_encoderItem.audioFilters removeObjectForKey:key];
    }
    
    return _encoderItem;
}

#pragma mark - IBActions

- (IBAction)cropEditorButtonAction:(id)sender {
}
- (IBAction)cropTextFieldAction:(id)sender {
}
- (IBAction)deinterlaceButtonAction:(NSButton *)sender {
}
- (IBAction)audioFadeInTextFieldAction:(id)sender {
}
- (IBAction)audioFadeOutTextFieldAction:(id)sender {
}
- (IBAction)audioPreampTextFieldAction:(id)sender {
}


@end
