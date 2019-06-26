//
//  SLHMainWindowController.m
//  Slash
//
//  Created by Terminator on 2018/11/14.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import "SLHMainWindowController.h"
#import "SLHDragView.h"
#import "SLHEncoderSettings.h"
#import "SLHEncoderItem.h"
#import "SLHEncoder.h"
#import "SLHEncoderQueue.h"
#import "SLHLogController.h"
#import "SLHMediaItem.h"
#import "SLHMediaItemTrack.h"
#import "SLHPreferences.h"
#import "SLHMetadataEditor.h"
#import "SLHMetadataItem.h"
#import "SLHPlayer.h"
#import "SLHMetadataIdentifiers.h"
#import "SLHEncoderBaseFormat.h"
#import "SLHEncoderX264Format.h"
#import "SLHEncoderVPXFormat.h"
#import "SLHEncoderVP9Format.h"
#import "SLHArgumentsViewController.h"
#import "SLHModalWindowController.h"
#import "SLHPresetManager.h"

extern NSString *const SLHMainWinodwEncoderFormatDidChange;

@interface SLHMainWindowController () <SLHDragViewDelegate, SLHPlayerDelegate, SLHPresetManagerDelegate, NSTableViewDelegate, NSWindowDelegate, NSMenuDelegate> {
    SLHDragView *_dragView;
    SLHEncoderSettings *_encoderSettings;
    SLHMetadataEditor *_metadataEditor;
    SLHPresetManager *_presetManager;
    SLHPlayer *_player;
    SLHPlayer *_auxPlayer;
    NSArray <SLHEncoderBaseFormat *> *_formats;
    SLHEncoderItem *_tempEncoderItem;
    SLHMediaItem *_currentMediaItem;
    NSString *_lastEncodedMediaFilePath;
    SLHEncoder *_encoder;
    SLHEncoderQueue *_queue;
    
    IBOutlet NSView *_customView;
    IBOutlet NSArrayController *_arrayController;
    IBOutlet NSTableView *_tableView;
    IBOutlet NSPopUpButton *_formatsPopUp;
    IBOutlet NSPopUpButton *_presetsPopUp;
    
    IBOutlet NSPopUpButton *_subtitlesStreamPopUp;
    IBOutlet NSPopUpButton *_audioStreamPopUp;
    IBOutlet NSPopUpButton *_videoStreamPopUp;
    IBOutlet NSTextView *_summaryTextView;
    IBOutlet NSTextField *_outputFileNameTextField;
    IBOutlet NSTextView *_mediaInfoTextView;

}

@end

@implementation SLHMainWindowController

- (NSString *)windowNibName {
    return self.className;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    /* SLHDragView */
    _dragView = [[SLHDragView alloc] init];
    _dragView.delegate = self;
    _dragView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    _dragView.frame = self.window.contentView.frame;
    [self.window.contentView addSubview:_dragView];
    
    /* SLHEncoderSettings */
    _encoderSettings = [[SLHEncoderSettings alloc] init];
    _encoderSettings.view.frame = _customView.frame;
    _encoderSettings.view.autoresizingMask = _customView.autoresizingMask;
    [_customView.superview replaceSubview:_customView with:_encoderSettings.view];
    
    /* SLHEncoder */
    _encoder = [[SLHEncoder alloc] init];
    
    /* SLHPresetManager */
    _presetManager = [[SLHPresetManager alloc] init];
    _presetManager.delegate = self;
    _presetsPopUp.menu.delegate = self;
    
    /* NSTableView */
    _tableView.delegate = self;
    
    /* SLHFormat */
    SLHEncoderX264Format *x264Fmt = [[SLHEncoderX264Format alloc] init];
    SLHEncoderVPXFormat *vpxFmt = [[SLHEncoderVPXFormat alloc] init];
    SLHEncoderVP9Format *vp9Fmt = [[SLHEncoderVP9Format alloc] init];
    
    _formats = @[x264Fmt, vpxFmt, vp9Fmt];
    NSMenu *formatsMenu = _formatsPopUp.menu;
    NSUInteger tag = 0;
    for (SLHEncoderBaseFormat *fmt in _formats) {
        NSMenuItem *itm = [formatsMenu addItemWithTitle:fmt.formatName action:nil keyEquivalent:@""];
        itm.tag = tag++;
    }
    NSString *name = SLHPreferences.preferences.lastUsedFormatName;
    if (name) {
        [_formatsPopUp selectItemWithTitle:name];
    }
}

#pragma mark - Methods

- (BOOL)hasSegments {
    return _arrayController.canRemove;
}

- (void)setCurrentMediaItem:(SLHMediaItem *)mediaItem {
    _currentMediaItem = mediaItem;
    [self _displayMediaInfo:mediaItem];
    [self _populatePopUpMenus:mediaItem];
    [_arrayController removeObjects:_arrayController.arrangedObjects];
    _tempEncoderItem = nil;
    [self.window setTitleWithRepresentedFilename:mediaItem.filePath];
}

- (SLHMediaItem *)currentMediaItem {
    return _currentMediaItem;
}

#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification {
    _player = nil;
    _auxPlayer = nil;
    SLHPreferences.preferences.lastUsedFormatName = _formatsPopUp.selectedItem.title;
    [_presetManager savePresets];
}

#pragma mark - NSTableView Delegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger row = _tableView.selectedRow;
    SLHEncoderItem *item = _arrayController.arrangedObjects[row];
    NSInteger tag = item.tag;
    [_formatsPopUp selectItemWithTag:tag];
    SLHEncoderBaseFormat *fmt = _formats[tag];
    fmt.encoderItem = item;
    _encoderSettings.delegate = fmt;
    if (_metadataEditor.hasWindow) {
        _metadataEditor.encoderItem = item;
    }
    [self _updatePopUpMenus:item];
}

#pragma mark - NSMenuDelegate

- (void)menuNeedsUpdate:(NSMenu *)menu {
    NSMenuItem *item = menu.itemArray[0];
    [menu removeAllItems];
    [menu addItem:item];
    SLHEncoderBaseFormat *fmt = _formats[_formatsPopUp.selectedTag];
    NSArray *presets = [_presetManager presetsForName:fmt.formatName];
    if (presets && presets.count) {
        for (NSDictionary *p in presets) {
            NSMenuItem *i = [[NSMenuItem alloc] initWithTitle:p[SLHEncoderPresetNameKey] action:nil keyEquivalent:@""];
            i.representedObject = p;
            [menu addItem:i];
        }
    }
}

#pragma mark - SLHPresetManagerDelegate 

- (void)presetManager:(SLHPresetManager *)manager loadPreset:(NSDictionary *)preset forName:(NSString *)name {
    [_formatsPopUp selectItemWithTitle:name];
    [self formatPopUpClicked:nil];
    SLHEncoderBaseFormat *fmt = _formats[_formatsPopUp.selectedTag];
    fmt.dictionaryRepresentation = preset;
    
    NSInteger row = _tableView.selectedRow;
    SLHEncoderItem *item = _arrayController.arrangedObjects[row];
    [self _updatePopUpMenus:item];
}

#pragma mark - SLHPlayer Delegate

- (void)player:(SLHPlayer *)p segmentStart:(double)start {
    if (!_tempEncoderItem || ![_arrayController.arrangedObjects containsObject:_tempEncoderItem]) {
        _tempEncoderItem = [self _createSegment];
        [_arrayController addObject:_tempEncoderItem];
    }
    _tempEncoderItem.intervalStart = start;
    [self updateSummary:nil];
}

- (void)player:(SLHPlayer *)p segmentEnd:(double)end {
    _tempEncoderItem.intervalEnd = end;
    [self updateSummary:nil];
}

- (void)playerDidEndEditingSegment:(SLHPlayer *)p {
    _tempEncoderItem = nil;
}

- (void)playerDidClearSegment:(SLHPlayer *)p {
    if (_tempEncoderItem) {
        [_arrayController removeObject:_tempEncoderItem];
    }
        _tempEncoderItem = nil;
}

#pragma mark - SLHDragView Delegate

- (void)didReceiveFilename:(NSString *)filename {
    SLHMediaItem *mediaItem = [SLHMediaItem mediaItemWithPath:filename];
    if (mediaItem.error) {
        NSLog(@"Error: %@", mediaItem.error.localizedDescription);
        return;
    }
    self.currentMediaItem = mediaItem;
}

- (void)didBeginDraggingSession {
    [self.window endEditingFor:self];
    _summaryTextView.hidden = YES;
}
- (void)didEndDraggingSession {
    _summaryTextView.hidden = NO;
}
- (void)didReceiveMouseEvent:(NSEvent *)event {
    
}

- (IBAction)addToQueue:(id)sender {
    BOOL shouldRemoveItems = (NSApp.currentEvent.modifierFlags & NSAlternateKeyMask);
    if (!_queue) {
        _queue = [[SLHEncoderQueue alloc] init];
    }
    NSArray *items = _arrayController.arrangedObjects;
    for (SLHEncoderItem *i in items) {
        SLHEncoderBaseFormat *fmt = _formats[i.tag];
        fmt.encoderItem = i;
        i.encoderArguments = fmt.arguments;
    }
    if (shouldRemoveItems) {
        [_queue addEncoderItems:items];
        [_arrayController removeObjects:items];
    }
}

#pragma mark - IBActions


- (IBAction)savePreset:(id)sender {
    SLHEncoderBaseFormat *fmt = _formats[_formatsPopUp.indexOfSelectedItem];
    [_presetManager setPreset:fmt.dictionaryRepresentation forName:fmt.formatName];
}

- (IBAction)showPresetsWindow:(id)sender {
    [_presetManager.window makeKeyAndOrderFront:nil];
}

- (IBAction)startEncoding:(id)sender {
    
    NSInteger row = _tableView.selectedRow;
    SLHEncoderItem *item = _arrayController.arrangedObjects[row];
    item.encoderArguments = _formats[item.tag].arguments;
    NSEvent *event = [NSApp currentEvent];
    
    if (event.modifierFlags & NSAlternateKeyMask) { // allow to edit arguments if the Option key is pressed
        SLHModalWindowController *win = [SLHModalWindowController new];
        SLHArgumentsViewController *argsView = [SLHArgumentsViewController new];
        win.title = @"Encoding Arguments";
        win.contentView = argsView.view;
        argsView.encoderItem = item;
        [win runModal];
    
    }
    [_encoder encodeItem:item usingBlock:^(SLHEncoderState state) {
        switch (state) {
            case SLHEncoderStateSuccess:
                _lastEncodedMediaFilePath = item.outputPath;
                [_encoder.window performClose:nil];
                if (SLHPreferences.preferences.updateFileName) {
                    [self updateOutputFileName:nil];
                }
                                                                
                break;
            case SLHEncoderStateFailed:
            {
                NSString *log = _encoder.encodingLog;
                if (log) {
                    SLHLogController *logController = [[SLHLogController alloc] init];
                    logController.log = log;
                    [logController runModal];
                }
            }
                break;
            case SLHEncoderStateCanceled:
                
                break;
            default:
                break;
        }
    }];
}

- (IBAction)previewSourceFile:(id)sender {

    if (!_player) {
        _player = [SLHPlayer playerWithMediaItem:_currentMediaItem];
        _player.delegate = self;
    } else {
        [_player replaceCurrentItemWithMediaItem:_currentMediaItem];
    }
    if (_player.error) {
        NSLog(@"Playback error: %@", _player.error.localizedDescription);
        return;
    }
    [_player play];
}

- (IBAction)previewSegment:(id)sender {
    NSInteger row = _tableView.selectedRow;
    SLHEncoderItem *item = _arrayController.arrangedObjects[row];
    SLHMediaItem *mediaItem = item.mediaItem;
    if (!_auxPlayer) {
        _auxPlayer = [SLHPlayer playerWithMediaItem:mediaItem];
    } else if (_auxPlayer.currentItem != mediaItem) {
        [_auxPlayer replaceCurrentItemWithMediaItem:mediaItem];
    }
    [_auxPlayer play];
    static const struct timespec s = { .tv_sec = 1, .tv_nsec = 0 };
    nanosleep(&s, NULL);
    [_auxPlayer loopStart:item.interval.start end:item.interval.end];
}

- (IBAction)previewOutputFile:(id)sender {
    SLHMediaItem *item = [SLHMediaItem mediaItemWithPath:_lastEncodedMediaFilePath];
    if (item.error) {
        return;
    }
    if (!_auxPlayer) {
        _auxPlayer = [SLHPlayer playerWithMediaItem:item];
    } else {
        [_auxPlayer replaceCurrentItemWithMediaItem:item];
    }
    if (_auxPlayer.error) {
        NSLog(@"Playback error: %@", _auxPlayer.error.localizedDescription);
        return;
    }
    [_auxPlayer play];
}


- (IBAction)showMetadataEditor:(id)sender {
    
    if (!_metadataEditor) {
        _metadataEditor = [[SLHMetadataEditor alloc] init];
    }
    NSInteger row = _tableView.selectedRow;
    SLHEncoderItem *item = _arrayController.arrangedObjects[row];
    [_metadataEditor showWindow:sender];
    _metadataEditor.encoderItem = item;
}

- (IBAction)addEncoderItem:(id)sender {

    SLHEncoderItem *encItem = [self _createSegment];
    [_arrayController addObject:encItem];
}

- (IBAction)formatPopUpClicked:(id)sender {
    NSInteger tag = _formatsPopUp.selectedTag;
    SLHEncoderBaseFormat *fmt = _formats[tag];
    (void)fmt.view; // load view
    _encoderSettings.delegate = fmt;
    NSInteger row = _tableView.selectedRow;
    SLHEncoderItem *item = _arrayController.arrangedObjects[row];
    item.tag = tag;
    fmt.encoderItem = item;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SLHMainWinodwEncoderFormatDidChange object:fmt];
    [self updateSummary:nil];
}

- (IBAction)presetsPopUpClicked:(id)sender {
    SLHEncoderBaseFormat *fmt = _formats[_formatsPopUp.selectedTag];
    fmt.dictionaryRepresentation = _presetsPopUp.selectedItem.representedObject;
    NSInteger row = _tableView.selectedRow;
    SLHEncoderItem *item = _arrayController.arrangedObjects[row];
    [self _updatePopUpMenus:item];
}

- (IBAction)selectOutputFileName:(id)sender {
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = NO;
    panel.canChooseFiles = NO;
    panel.canChooseDirectories = YES;
    panel.canCreateDirectories = YES;
    
    [panel beginWithCompletionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSFileHandlingPanelOKButton) {
            NSString *path = panel.URL.path;
            NSInteger row = _tableView.selectedRow;
            SLHEncoderItem *item = _arrayController.arrangedObjects[row];
            NSString *outname = item.outputFileName;
            item.outputPath = [NSString stringWithFormat:@"%@/%@", path, outname];
        }
    }];

}

- (IBAction)videoStreamPopUpAction:(NSMenuItem *)sender {
    NSInteger row = _tableView.selectedRow;
    SLHEncoderItem *item = _arrayController.arrangedObjects[row];
    item.videoStreamIndex = sender.tag;
}

- (IBAction)audioStreamPopUpAction:(NSMenuItem *)sender {
    NSInteger row = _tableView.selectedRow;
    SLHEncoderItem *item = _arrayController.arrangedObjects[row];
    item.audioStreamIndex = sender.tag;
}

- (IBAction)subtitlesStreamPopUpAction:(NSMenuItem *)sender {
    NSInteger row = _tableView.selectedRow;
    SLHEncoderItem *item = _arrayController.arrangedObjects[row];
    item.subtitlesStreamIndex = sender.tag;
}

- (IBAction)updateSummary:(id)sender {
    NSInteger row = _tableView.selectedRow;
    SLHEncoderItem *item = _arrayController.arrangedObjects[row];
    _summaryTextView.string = item.summary;
}

- (IBAction)updateOutputFileName:(id)sender {
    NSInteger row = _tableView.selectedRow;
    SLHEncoderItem *encoderItem = _arrayController.arrangedObjects[row];
    NSString *extension = encoderItem.container;
    NSString *sourcePath = encoderItem.mediaItem.filePath;
    if (!extension) {
        extension = sourcePath.pathExtension;
    }    
    NSString *outputName = sourcePath.lastPathComponent.stringByDeletingPathExtension;
    outputName = [outputName stringByAppendingFormat:@"_%lu%02u.%@", time(0), arc4random_uniform(100), extension];
    encoderItem.outputFileName = outputName;

}

#pragma mark - Private 

- (void)_populatePopUpMenus:(SLHMediaItem *)mediaItem {
    NSMenuItem *item;
    [_videoStreamPopUp removeAllItems];
    [_audioStreamPopUp removeAllItems];
    [_subtitlesStreamPopUp removeAllItems];
    for (SLHMediaItemTrack *t in mediaItem.tracks) {
        NSUInteger trackIndex = t.trackIndex;
        switch (t.mediaType) {
            case SLHMediaTypeVideo:
            {
                item = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%lu: (%.0fx%.0f, %@)", trackIndex, t.videoSize.width, t.videoSize.height, t.codecName] action:@selector(videoStreamPopUpAction:) keyEquivalent:@""];
                item.tag = trackIndex;
                item.target = self;
                [_videoStreamPopUp.menu addItem:item];
            }
                break;
            case SLHMediaTypeAudio:
            {
                item = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%lu: (%@, %@, %@, %lukbs)", trackIndex, t.codecName, t.language, t.channelLayout, t.bitRate / 1000] action:@selector(audioStreamPopUpAction:) keyEquivalent:@""];
                item.tag = trackIndex;
                item.target = self;
                [_audioStreamPopUp.menu addItem:item];
            }
                break;
            case SLHMediaTypeText:
            {
                item = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%lu: (%@, %@)", trackIndex, t.language, t.codecName] action:@selector(subtitlesStreamPopUpAction:) keyEquivalent:@""];
                item.tag = trackIndex;
                item.target = self;
                [_subtitlesStreamPopUp.menu addItem:item];
            }
                break;
                
            default:
                break;
        }
    }
    item = [[NSMenuItem alloc] initWithTitle:@"none" action:@selector(videoStreamPopUpAction:) keyEquivalent:@""];
    item.tag = -1;
    item.target = self;
    [_videoStreamPopUp.menu addItem:item.copy];
    item.action = @selector(audioStreamPopUpAction:);
    [_audioStreamPopUp.menu addItem:item.copy];
    item.action = @selector(subtitlesStreamPopUpAction:);
    [_subtitlesStreamPopUp.menu addItem:item.copy];
}

- (void)_updatePopUpMenus:(SLHEncoderItem *)item {
    [_videoStreamPopUp selectItemWithTag:item.videoStreamIndex];
    [_audioStreamPopUp selectItemWithTag:item.audioStreamIndex];
    [_subtitlesStreamPopUp selectItemWithTag:item.subtitlesStreamIndex];
}

- (SLHEncoderItem *)_createSegment {
    NSString *outputPath = nil;
    NSString *sourcePath = _currentMediaItem.filePath;
    SLHPreferences *prefs = [SLHPreferences preferences];
    if (prefs.outputPathSameAsInput) {
        outputPath = [sourcePath stringByDeletingLastPathComponent];
    } else {
        outputPath = prefs.currentOutputPath;
    }
    
    SLHEncoderItem *encoderItem = nil;
    NSInteger row = _tableView.selectedRow;
    if (row >= 0) {         // Make a copy of a selected item
        SLHEncoderItem *item = _arrayController.arrangedObjects[row];
        encoderItem = item.copy;
    } else {                // Create a new item
        encoderItem = [[SLHEncoderItem alloc] initWithMediaItem:_currentMediaItem outputPath:@""];
        encoderItem.interval = (TimeInterval){0, _currentMediaItem.duration};
        encoderItem.tag = _formatsPopUp.selectedTag;
    }
    
    NSString *extension = encoderItem.container;
    if (!extension) {
        extension = sourcePath.pathExtension;
    }

    NSString *outputName = sourcePath.lastPathComponent.stringByDeletingPathExtension;
    outputName = [outputName stringByAppendingFormat:@"_%lu%02u.%@", time(0), arc4random_uniform(100), extension];
    encoderItem.outputPath = [outputPath stringByAppendingPathComponent:outputName];
    encoderItem.outputFileName = outputName;

    return encoderItem;
}

- (void)_displayMediaInfo:(SLHMediaItem *)mediaItem {
    
    NSMutableString *mediaInfo = [NSMutableString new];
    [mediaInfo appendFormat:@"Duration: %.3f, bitrate: %lu kb/s, format: %@\n\n", mediaItem.duration, mediaItem.bitRate / 1000, mediaItem.formatName];
    [mediaInfo appendString:@"Streams:\n"];
     for (SLHMediaItemTrack *t in mediaItem.tracks) {
         SLHMediaType type = t.mediaType;
         switch (type) {
             case SLHMediaTypeVideo:
                 [mediaInfo appendFormat:
                 @"      Video #%lu: %@(%@), ""%.0fx%0.f, ""%@, ""%.2f fps\n",
                  t.trackIndex, t.codecName, t.encodingProfile, t.videoSize.width, t.videoSize.height,
                  t.pixelFormat, t.frameRate];
                 break;
             case  SLHMediaTypeAudio:
                 [mediaInfo appendFormat:
                 @"      Audio #%lu:"" %@, ""%@, %@, ""%@ Hz\n",
                  t.trackIndex, t.codecName, t.channelLayout, t.language, t.sampleRate];
                 break;
             case SLHMediaTypeText:
                 [mediaInfo appendFormat:
                 @"  Subtitles #%lu:"" %@, ""%@\n", t.trackIndex, t.codecName, t.language];
                 break;
             case SLHMediaTypeUnknown:
                 [mediaInfo appendFormat:
                 @"    Unknown #%lu:"" %@\n", t.trackIndex,  t.codecName];
                 break;
                 
             default:
                 break;
         }
          
     }
    [mediaInfo appendString:@"\n\nMetadata:\n"];
    for (SLHMetadataItem *i in mediaItem.metadata) {
        [mediaInfo appendFormat:@"  %@: %@\n", i.identifier, i.value];
    }
    _mediaInfoTextView.string = mediaInfo;
}

@end
