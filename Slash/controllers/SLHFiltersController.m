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
#import "SLHPresetManager.h"
#import "SLHPreferences.h"
#import "SLHTextEditor.h"
#import "SLHExternalPlayer.h"

#import "MPVPlayerItem.h"
#import "MPVPlayerItemTrack.h"

extern NSString *const SLHPreferencesMPVFilePathKey;

extern NSString *const SLHEncoderVideoFiltersKey;
extern NSString *const SLHEncoderAudioFiltersKey;

extern NSString *const SLHEncoderFiltersVideoCropKey;
extern NSString *const SLHEncoderFiltersVideoDeinterlaceKey;
extern NSString *const SLHEncoderFiltersAudioFadeInKey;
extern NSString *const SLHEncoderFiltersAudioFadeOutKey;
extern NSString *const SLHEncoderFiltersAudioPreampKey;

extern NSString *const SLHEncoderFiltersEnableVideoFiltersKey;
extern NSString *const SLHEncoderFiltersEnableAudioFiltersKey;
extern NSString *const SLHEncoderFiltersBurnSubtitlesKey;
extern NSString *const SLHEncoderFiltersForceSubtitlesStyleKey;
extern NSString *const SLHEncoderFiltersSubtitlesStyleKey;
extern NSString *const SLHEncoderFiltersAdditionalVideoFiltersKey;
extern NSString *const SLHEncoderFiltersAdditionalAudioFiltersKey;

static NSString *const _videoCropFmt = @"crop=w=%ld:h=%ld:x=%ld:y=%ld";
static NSString *const _audioFadeInFmt = @"afade=t=in:d=%.3f";
static NSString *const _audioFadeOutFmt = @"afade=t=out:d=%.3f:st=%.3f";
static NSString *const _audioPreampFmt = @"acompressor=makeup=%ld";
static NSString *const _filterPresetsNameKey = @"Filters";


@interface SLHFiltersController () <NSMenuDelegate, SLHPresetManagerDelegate> {
    
    SLHEncoderItem *_encoderItem;
    SLHPresetManager *_presetManager;
    SLHTextEditor *_textEditor;
    NSPopover *_popover;
    NSString *_editKey;
    
    IBOutlet SLHCropEditor *_cropEditor;
    IBOutlet NSTextField *_subtitlesNameTextField;
    IBOutlet NSPopUpButton *_presetsPopUp;
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

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSString *presetsPath = SLHPreferences.preferences.appSupportPath;
        presetsPath = [presetsPath stringByAppendingPathComponent:@"filters.dict"];
        _presetManager = [[SLHPresetManager alloc] initWithPresetsPath:presetsPath];
        _textEditor = SLHTextEditor.new;
        [_textEditor.view setNeedsDisplay:YES];
        NSButton *button = _textEditor.doneButton;
        button.action = @selector(popoverDone:);
        button.target = self;
        button = _textEditor.cancelButton;
        button.action = @selector(popoverCancel:);
        button.target = self;
        _popover = [[NSPopover alloc] init];
        _popover.behavior =  NSPopoverBehaviorTransient;
        _popover.contentViewController = _textEditor;
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationWillClose:) name:NSApplicationWillTerminateNotification object:nil];
    }
    return self;
}

- (NSString *)nibName {
    return self.className;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)applicationWillClose:(NSNotification *)notification {
    if (_presetManager.hasChanges) {
        [_presetManager savePresets];
    }
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

#pragma mark - Methods

static inline NSString *_cropString(SLHEncoderItem *item) {
    SLHFilterOptions *opts = item.filters;
    NSInteger y = opts.videoCropY;
    NSInteger h = opts.videoCropHeight;
    NSInteger idx = item.videoStreamIndex;
    if (idx > -1) {
        y = item.playerItem.tracks[idx].videoSize.height - h - y;
    }
    return [NSString stringWithFormat:_videoCropFmt, opts.videoCropWidth, h, opts.videoCropX, y];
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
            [str appendString:_cropString(_encoderItem)];
        }
        
        if (opts.videoDeinterlace) {
            if (str) {
                [str appendString:@","];
            } else {
                str = [NSMutableString new];
            }
            [str appendString:SLHEncoderFiltersVideoDeinterlaceKey];
        }
        
        if (opts.burnSubtitles) {
            NSString *filterArgs = nil;
            NSInteger streamIdx = _encoderItem.subtitlesStreamIndex;
            if (streamIdx > -1) {
            
                NSInteger subtitlesIdx = -1;
                for (MPVPlayerItemTrack *t in _encoderItem.playerItem.tracks) {
                    if (t.mediaType == MPVMediaTypeText) {
                        subtitlesIdx++;
                        if (t.trackIndex == streamIdx) {
                            break;
                        }
                    }
                }
               filterArgs = [NSString stringWithFormat:
                                 @"subtitles='%@':si=%li", _encoderItem.playerItem.filePath , subtitlesIdx];
            } else if (opts.subtitlesPath) {
                filterArgs = [NSString stringWithFormat:
                              @"subtitles='%@'", opts.subtitlesPath];
            }
            
            if (filterArgs) {
                if (opts.forceSubtitlesStyle) {
                    NSString *style = opts.subtitlesStyle;
                    filterArgs = [filterArgs stringByAppendingFormat:@":force_style='%@'", style];
                }
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
        
        NSString *filters = opts.additionalVideoFiltersString;
        if (filters.length) {
            if (str) {
                [str appendString:@","];
            } else {
                str = NSMutableString.new;
            }
            [str appendString:filters];
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
        
        NSString *filters = opts.additionalAudioFiltersString;
        if (filters.length) {
            if (str) {
                [str appendString:@","];
            } else {
                str = NSMutableString.new;
            }
            [str appendString:filters];
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
    if (_cropEditor.hasWindow && _encoderItem && _encoderItem.playerItem.hasVideoStreams) {
        _cropEditor.encoderItem = encoderItem;
    }
    
    [self _updateSubtitlesName];
}

- (SLHEncoderItem *)encoderItem {
    return _encoderItem;
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dict = NSMutableDictionary.new;
    SLHFilterOptions *opts = _encoderItem.filters;
    dict[SLHEncoderFiltersEnableVideoFiltersKey] = @(opts.enableVideoFilters);
    NSRect rect = NSMakeRect(opts.videoCropX, opts.videoCropY, opts.videoCropWidth, opts.videoCropHeight);
    dict[SLHEncoderFiltersVideoCropKey] = NSStringFromRect(rect);
    dict[SLHEncoderFiltersVideoDeinterlaceKey] = @(opts.videoDeinterlace);
    dict[SLHEncoderFiltersBurnSubtitlesKey] = @(opts.burnSubtitles);
    dict[SLHEncoderFiltersForceSubtitlesStyleKey] = @(opts.forceSubtitlesStyle);
    dict[SLHEncoderFiltersSubtitlesStyleKey] = opts.subtitlesStyle.copy;
    dict[SLHEncoderFiltersAdditionalVideoFiltersKey] = opts.additionalVideoFiltersString.copy;
    
    dict[SLHEncoderFiltersEnableAudioFiltersKey] = @(opts.enableAudioFilters);
    dict[SLHEncoderFiltersAudioFadeInKey] = @(opts.audioFadeIn);
    dict[SLHEncoderFiltersAudioFadeOutKey] = @(opts.audioFadeOut);
    dict[SLHEncoderFiltersAudioPreampKey] = @(opts.audioPreamp);
    dict[SLHEncoderFiltersAdditionalAudioFiltersKey] = opts.additionalAudioFiltersString;
    
    return dict;
}

- (void)setDictionaryRepresentation:(NSDictionary *)dict {
    NSNumber *val;
    SLHFilterOptions *opts = _encoderItem.filters;
    
    // Video Filters
    
    val = dict[SLHEncoderFiltersEnableVideoFiltersKey];
    opts.enableVideoFilters = val.boolValue;
    
    NSString *str = dict[SLHEncoderFiltersVideoCropKey];
    if (str) {
        NSRect rect = NSRectFromString(str);
        opts.videoCropX = rect.origin.x;
        opts.videoCropY = rect.origin.y;
        opts.videoCropWidth = rect.size.width;
        opts.videoCropHeight = rect.size.height;
    }
    
    val = dict[SLHEncoderFiltersVideoDeinterlaceKey];
    opts.videoDeinterlace = val.boolValue;
    
    val =  dict[SLHEncoderFiltersBurnSubtitlesKey];
    opts.burnSubtitles = val.boolValue;
    
    val = dict[SLHEncoderFiltersForceSubtitlesStyleKey];
    opts.forceSubtitlesStyle = val.boolValue;
    
    str = dict[SLHEncoderFiltersSubtitlesStyleKey];
    if (str) {
        opts.subtitlesStyle = str;
    }
    
    str = dict[SLHEncoderFiltersAdditionalVideoFiltersKey];
    if (str) {
        opts.additionalVideoFiltersString = str;
    }
    
    // Audio Filters
    
    val = dict[SLHEncoderFiltersEnableAudioFiltersKey];
    opts.enableAudioFilters = val.boolValue;
    
    val = dict[SLHEncoderFiltersAudioFadeInKey];
    opts.audioFadeIn = val.floatValue;
    
    val = dict[SLHEncoderFiltersAudioFadeOutKey];
    opts.audioFadeOut = val.floatValue;
    
    val = dict[SLHEncoderFiltersAudioPreampKey];
    opts.audioPreamp = val.integerValue;
    
    str = dict[SLHEncoderFiltersAdditionalAudioFiltersKey];
    if (str) {
        opts.additionalAudioFiltersString = str;
    }
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
    NSInteger idx = _encoderItem.videoStreamIndex;
    if ((r.size.height <= 0) || (r.size.width <= 0 || idx == -1)) {
        NSBeep();
        return;
    }
    
    MPVPlayerItem *playerItem = _encoderItem.playerItem;
    r.origin.y = playerItem.tracks[idx].videoSize.height - NSHeight(r) - NSMinY(r);

    SLHExternalPlayer *player = [SLHExternalPlayer defaultPlayer];
    if (player.error) {
        NSBeep();
        [self presentError:player.error];
        return;
    }
    
    player.url = playerItem.url;
    
    [player setVideoFilter:[NSString stringWithFormat:@"lavfi=[crop=w=%.0f:h=%.0f:x=%.0f:y=%.0f]",
                            NSWidth(r), NSHeight(r), NSMinX(r), NSMinY(r)]];
    [player seekTo:_encoderItem.interval.start];
    [player play];
    [player orderFront];
    
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

- (IBAction)applyPreset:(NSPopUpButton *)sender {
    NSDictionary *dict = sender.selectedItem.representedObject;
    self.dictionaryRepresentation = dict;
}

- (IBAction)savePreset:(id)sender {
    NSDictionary *dict = self.dictionaryRepresentation;
    [_presetManager setPreset:dict forName:_filterPresetsNameKey];
    [_presetManager savePresets];
}

- (IBAction)managePresets:(id)sender {
    [_presetManager showPresetsWindow:nil];
}

- (IBAction)editSubtitlesStyle:(NSButton *)sender {
    _editKey = @"subtitlesStyle";
    _textEditor.textView.string = _encoderItem.filters.subtitlesStyle;
    [_popover showRelativeToRect:sender.frame ofView:sender.superview preferredEdge:NSMinYEdge];
}

- (IBAction)editCustomVideoFilters:(NSButton *)sender {
    _editKey = @"additionalVideoFiltersString";
    _textEditor.textView.string = _encoderItem.filters.additionalVideoFiltersString;
    [_popover showRelativeToRect:sender.frame ofView:sender.superview preferredEdge:NSMinYEdge];
}

- (IBAction)editCustomAudioFilters:(NSButton *)sender {
    _editKey = @"additionalAudioFiltersString";
    _textEditor.textView.string = _encoderItem.filters.additionalAudioFiltersString;
    [_popover showRelativeToRect:sender.frame ofView:sender.superview preferredEdge:NSMinYEdge];
}

- (IBAction)popoverDone:(id)sender {
    [_encoderItem.filters setValue:_textEditor.textView.string.copy forKey:_editKey];
    [_popover close];
}

- (IBAction)popoverCancel:(id)sender {
    [_popover close];
}

#pragma mark - SLHPresetManagerDelegate 

- (void)presetManager:(SLHPresetManager *)manager loadPreset:(NSDictionary *)preset forName:(NSString *)name {
    self.dictionaryRepresentation = preset;
}

#pragma mark - NSMenuDelegate

- (void)menuNeedsUpdate:(NSMenu *)menu {
    NSMenuItem *item = menu.itemArray.firstObject;
    [menu removeAllItems];
    [menu addItem:item];
    NSArray *presets = [_presetManager presetsForName:_filterPresetsNameKey];
    for (NSDictionary *dict in presets) {
        item = [[NSMenuItem alloc] initWithTitle:dict[SLHEncoderPresetNameKey] action:nil keyEquivalent:@""];
        item.representedObject = dict;
        [menu addItem:item];
    }
}

#pragma mark - Private

- (void)_updateSubtitlesName {
    NSInteger subsIdx = _encoderItem.subtitlesStreamIndex;
    if (subsIdx > -1) {
        MPVPlayerItemTrack *t = _encoderItem.playerItem.tracks[subsIdx];
        _subtitlesNameTextField.stringValue = [NSString stringWithFormat:@"#%li: (%@, %@)", subsIdx, t.codecName, t.language];
    } else if (_encoderItem.filters.subtitlesPath) {
        _subtitlesNameTextField.stringValue = _encoderItem.filters.subtitlesPath.lastPathComponent;
    } else {
        _subtitlesNameTextField.stringValue = @"";
    }
}

@end
