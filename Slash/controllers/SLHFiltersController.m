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
#import "SLHMediaItemTrack.h"

extern NSString *const SLHPreferencesMPVFilePathKey;

extern NSString *const SLHEncoderVideoFiltersKey;
extern NSString *const SLHEncoderAudioFiltersKey;

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
    
    SLHEncoderItem *_encoderItem;
    
    IBOutlet SLHCropEditor *_cropEditor;
    IBOutlet NSTextField *_subtitlesNameTextField;
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

#pragma mark - Methods

static inline NSString *_cropString(SLHFilterOptions *opts) {
    return [NSString stringWithFormat:_videoCropFmt, opts.videoCropWidth, opts.videoCropHeight, opts.videoCropX, opts.videoCropY];
}

static inline NSString *_fadeInString(double val) {
    return [NSString stringWithFormat:_audioFadeInFmt, val];
}

static inline NSString *_fadeOutString(double val, double stop) {
    return [NSString stringWithFormat:_audioFadeOutFmt, val, stop];
}

static inline NSString *_preampString(NSInteger val) {
    return [NSString stringWithFormat:_audioPreampFmt, val];
}

- (NSArray *)arguments {
    NSMutableArray *args = [NSMutableArray new];
    SLHFilterOptions *opts = _encoderItem.filters;
    
    // Video Filters
    
    if (opts.enableVideoFilters) {
        NSMutableString *str = nil;
        if (opts.videoCropX || opts.videoCropY || opts.videoCropWidth || opts.videoCropHeight) {
            str = [NSMutableString new];
            [str appendString:_cropString(opts)];
        }
        
        if (opts.videoDeinterlace) {
            if (str) {
                [str appendString:@","];
            } else {
                str = [NSMutableString new];
            }
            [str appendString:SLHEncoderVideoFilterDeinterlaceKey];
        }
        
        if (opts.burnSubtitles) {
            NSString *filterArgs = nil;
            NSInteger streamIdx = _encoderItem.subtitlesStreamIndex;
            if (streamIdx > -1) {
            
                NSInteger subtitlesIdx = -1;
                for (SLHMediaItemTrack *t in _encoderItem.mediaItem.tracks) {
                    if (t.mediaType == SLHMediaTypeText) {
                        subtitlesIdx++;
                        if (t.trackIndex == streamIdx) {
                            break;
                        }
                    }
                }
               filterArgs = [NSString stringWithFormat:
                                 @"subtitles='%@':si=%li", _encoderItem.mediaItem.filePath , subtitlesIdx];
            } else if (opts.subtitlesPath) {
                filterArgs = [NSString stringWithFormat:
                              @"subtitles='%@'", opts.subtitlesPath];
            }
            
            if (filterArgs) {
                double startTime = _encoderItem.interval.start;
                if (startTime > 0) {
                    filterArgs = [NSString stringWithFormat:@"setpts=PTS+%.3f/TB,%@,setpts=PTS-STARTPTS", startTime, filterArgs];
                }
                if (str) {
                    [str appendString:@","];
                } else {
                    str = [NSMutableString new];
                }
                [str appendString:filterArgs];
            }
        }
        
        if (str) {
            [args addObject:SLHEncoderVideoFiltersKey];
            [args addObject:str];
        }
    }
    
    // Audio Filters
    
    if (opts.enableAudioFilters) {
        NSMutableString *str = nil;
        if (opts.audioFadeIn > 0) {
            str = [NSMutableString new];
            [str appendString:_fadeInString(opts.audioFadeIn)];
        }
        
        if (opts.audioFadeOut > 0) {
            if (str) {
                [str appendString:@","];
            } else {
                str = [NSMutableString new];
            }
            double val = opts.audioFadeOut;
            double stop = _encoderItem.interval.end - _encoderItem.interval.start - val;
            [str appendString:_fadeOutString(val, stop)];
        }
        
        if (opts.audioPreamp) {
            if (str) {
                [str appendString:@","];
            } else {
                str = [NSMutableString new];
            }
            [str appendString:_preampString(opts.audioPreamp)];
        }
        
        if (str) {
            [args addObject:SLHEncoderAudioFiltersKey];
            [args addObject:str];
        }
    }
    return args;
}

#pragma mark - Properties

- (void)setEncoderItem:(SLHEncoderItem *)encoderItem {
    _encoderItem = encoderItem;
    if (_cropEditor.hasWindow && _encoderItem) {
        _cropEditor.encoderItem = encoderItem;
    }
    
    [self _updateSubtitlesName];
}

- (SLHEncoderItem *)encoderItem {
    return _encoderItem;
}

#pragma mark - IBActions

- (IBAction)resetCropArea:(id)sender {
    SLHFilterOptions *options = _encoderItem.filters;
    options.videoCropX = 0;
    options.videoCropY = 0;
    options.videoCropHeight = 0;
    options.videoCropWidth = 0;
}

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

- (IBAction)subtitlesPath:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = NO;
    panel.allowedFileTypes = @[@"srt", @"vtt", @"ass", @"ssa"];
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSFileHandlingPanelOKButton) {
            NSString *value = panel.URLs.firstObject.path;
            _encoderItem.filters.subtitlesPath = value;
            _subtitlesNameTextField.stringValue = value.lastPathComponent;
        }
    }];
}

- (IBAction)burnSubtitles:(NSButton *)sender {
    if (sender.state == NSOnState) {
        [self _updateSubtitlesName];
    }
}

#pragma mark - Private

- (void)_updateSubtitlesName {
    NSInteger subsIdx = _encoderItem.subtitlesStreamIndex;
    if (subsIdx > -1) {
        SLHMediaItemTrack *t = _encoderItem.mediaItem.tracks[subsIdx];
        _subtitlesNameTextField.stringValue = [NSString stringWithFormat:@"#%li: (%@, %@)", subsIdx, t.codecName, t.language];
    } else if (_encoderItem.filters.subtitlesPath) {
        _subtitlesNameTextField.stringValue = _encoderItem.filters.subtitlesPath.lastPathComponent;
    } else {
        _subtitlesNameTextField.stringValue = @"";
    }
}

@end
