//
//  SLHEncoderUniversalFormat.m
//  Slash
//
//  Created by Terminator on 2019/06/28.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHEncoderUniversalFormat.h"
#import "SLHEncoderUniversalOptions.h"
#import "SLHEncoderItem.h"
#import "SLHMediaItem.h"
#import "SLHFiltersController.h"
#import "SLHEncoderItemMetadata.h"
#import "SLHPreferences.h"
#import "SLHTextEditor.h"

#import "MPVPlayerItem.h"
#import "MPVPlayerItemTrack.h"

extern NSString *const SLHEncoderUniversalVideoArgumentsKey;
extern NSString *const SLHEncoderUniversalAudioArgumentsKey;

extern NSString *const SLHEncoderMediaStartTimeKey;
extern NSString *const SLHEncoderMediaEndTimeKey;
extern NSString *const SLHEncoderMediaOverwriteFilesKey;
extern NSString *const SLHEncoderMediaThreadsKey;

@interface SLHEncoderUniversalFormat () <NSTableViewDataSource> {

    IBOutlet NSTableView *_tableView;
    NSMutableArray *_dataSource;
    SLHFiltersController *_filters;
    SLHEncoderItem *_encoderItem;
    SLHTextEditor *_textEditor;
    NSPopover *_popover;
}

@property SLHEncoderUniversalOptions *videoArguments;
@property SLHEncoderUniversalOptions *audioArguments;

@end

@implementation SLHEncoderUniversalFormat

- (NSString *)nibName {
    return self.className;
}

- (NSString *)formatName {
    return @"Universal";
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _filters = [SLHFiltersController filtersController];
    _filters.encoderItem = _encoderItem;
    _textEditor = SLHTextEditor.new;
    NSRect frame = NSMakeRect(0, 0, 250, 400);
    _textEditor.view.frame = frame;
    _textEditor.textView.string = @"";
    
    NSButton *button = _textEditor.doneButton;
    button.action = @selector(popoverDone:);
    button.target = self;
    button = _textEditor.cancelButton;
    button.action = @selector(popoverCancel:);
    button.target = self;
    
    _popover = NSPopover.new;
    _popover.behavior =  NSPopoverBehaviorTransient;
    _popover.contentViewController = _textEditor;
}

- (void)setEncoderItem:(SLHEncoderItem *)encoderItem {
    super.encoderItem = encoderItem;
    _encoderItem = encoderItem;
    
    SLHEncoderUniversalOptions *opts = (id)encoderItem.videoOptions;
    if (![opts isKindOfClass:SLHEncoderUniversalOptions.class]) {
        opts = [[SLHEncoderUniversalOptions alloc] initWithOptions:opts];
        encoderItem.videoOptions = opts;
    }
    _videoArguments = opts;
    
    opts = (id)encoderItem.audioOptions;
    if (![opts isKindOfClass:SLHEncoderUniversalOptions.class]) {
        opts = [[SLHEncoderUniversalOptions alloc] initWithOptions:opts];
        encoderItem.audioOptions = opts;
    }
    _audioArguments = opts;
    
    _dataSource = _videoArguments.arguments;
    _filters.encoderItem = _encoderItem;
    [_tableView reloadData];
}

- (SLHEncoderItem *)encoderItem {
    return _encoderItem;
}

- (void)setDictionaryRepresentation:(NSDictionary *)dict {
    NSArray *args = dict[SLHEncoderUniversalVideoArgumentsKey];
    if (args) {
        _videoArguments.arguments = args.mutableCopy;
        _dataSource = _videoArguments.arguments;
        [_tableView reloadData];
    }
    
    args = dict[SLHEncoderUniversalAudioArgumentsKey];
    if (args) {
        _audioArguments.arguments = args.mutableCopy;
    }
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dict = NSMutableDictionary.new;
    dict[SLHEncoderUniversalVideoArgumentsKey] = _videoArguments.arguments.copy;
    dict[SLHEncoderUniversalAudioArgumentsKey] = _audioArguments.arguments.copy;
    return dict;
}

- (NSArray<NSArray *> *)arguments {
    NSMutableArray *args = NSMutableArray.new;
    NSString *ffmpegPath = SLHPreferences.preferences.ffmpegPath;
    if (!ffmpegPath) {
        NSLog(@"%s: ffmpeg file path is not set", __PRETTY_FUNCTION__);
        return nil;
    }
    TimeInterval ti = _encoderItem.interval;
    [args addObjectsFromArray:@[ ffmpegPath, @"-nostdin", @"-hide_banner",
                                 SLHEncoderMediaOverwriteFilesKey,
                                 SLHEncoderMediaStartTimeKey,
                                 @(ti.start).stringValue,
                                 SLHEncoderMediaEndTimeKey,
                                 @(ti.end - ti.start).stringValue,
                                 @"-i", _encoderItem.playerItem.filePath]];
    [args addObjectsFromArray:_videoArguments.arguments];
    [args addObjectsFromArray:_audioArguments.arguments];
    [args addObjectsFromArray:_filters.arguments];
    [args addObjectsFromArray:_encoderItem.metadata.arguments];
    [args addObject:_encoderItem.outputPath];
    return @[args];
}

#pragma mark - IBActions

- (IBAction)addArgument:(id)sender {
    NSInteger idx = _tableView.selectedRow + 1;
    [_dataSource insertObject:@"(Empty)" atIndex:idx];
    [_tableView reloadData];
    [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
    [_tableView scrollRowToVisible:idx];
}

- (IBAction)removeArgument:(id)sender {
    NSInteger idx = _tableView.selectedRow;
    if (idx > -1) {
        [_dataSource removeObjectAtIndex:idx--];
        [_tableView reloadData];
        [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
        [_tableView scrollRowToVisible:idx];
    } else {
        NSBeep();
    }
}

- (IBAction)showTextEditor:(NSButton *)sender {
    [_popover showRelativeToRect:sender.frame ofView:self.view preferredEdge:NSMinYEdge];
}

- (IBAction)popoverDone:(id)sender {
    NSString *string = _textEditor.textView.string;
    NSArray *array = [string componentsSeparatedByString:@"\n"];
    [_dataSource addObjectsFromArray:array];
    [_tableView reloadData];
    [_popover close];
    _textEditor.textView.string = @"";
}

- (IBAction)popoverCancel:(id)sender {
    [_popover close];
}

#pragma mark - NSTableView DataSource

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row < _dataSource.count) {
        return _dataSource[row];
    }
    return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row < _dataSource.count && object) {
        _dataSource[row] = object;
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _dataSource.count;
}

#pragma mark - SLHEncoderSettingsDelegate

- (NSView *)encoderSettings:(SLHEncoderSettings *)enc viewForTab:(SLHEncoderSettingsTab) tab {
    
    if (_encoderItem == nil) {
        return self.noSelectionView;
    }
    
    switch (tab) {
        case SLHEncoderSettingsVideoTab:
            _dataSource = _videoArguments.arguments;
            break;
        case SLHEncoderSettingsAudioTab:
            _dataSource = _audioArguments.arguments;
            break;
        case SLHEncoderSettingsFiltersTab:
            return _filters.view;
            break;
            
        default:
            return [super encoderSettings:enc viewForTab:tab];
            break;
    }
    [_tableView reloadData];
    return self.view;
}



@end
