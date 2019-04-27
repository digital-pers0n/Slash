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
#import "SLHMediaItem.h"
#import "SLHMediaItemTrack.h"
#import "SLHPreferences.h"
#import "SLHMetadataEditor.h"
#import "SLHMetadataItem.h"
#import "SLHPlayer.h"
#import "SLHMetadataIdentifiers.h"
#import "SLHEncoderBaseFormat.h"
#import "SLHEncoderX264Format.h"

@interface SLHMainWindowController () <SLHDragViewDelegate, SLHPlayerDelegate, SLHMetadataEditorDelegate, NSTableViewDelegate> {
    SLHDragView *_dragView;
    SLHEncoderSettings *_encoderSettings;
    SLHMetadataEditor *_metadataEditor;
    SLHPlayer *_player;
    NSArray <SLHEncoderBaseFormat *> *_formats;
    SLHEncoderItem *_tempEncoderItem;
    SLHMediaItem *_currentMediaItem;
    
    IBOutlet NSView *_customView;
    IBOutlet NSArrayController *_arrayController;
    IBOutlet NSTableView *_tableView;
    IBOutlet NSPopUpButton *_formatsPopUp;
    
    IBOutlet NSPopUpButton *_subtitlesStreamPopUp;
    IBOutlet NSPopUpButton *_audioStreamPopUp;
    IBOutlet NSPopUpButton *_videoStreamPopUp;
    IBOutlet NSTextView *_summaryTextView;
    IBOutlet NSTextField *_outputFileNameTextField;

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
    
    /* NSTableView */
    _tableView.delegate = self;
    
    /* SLHFormat */
    SLHEncoderX264Format *x264Fmt = [[SLHEncoderX264Format alloc] init];

    _formats = @[x264Fmt];
    NSMenu *formatsMenu = _formatsPopUp.menu;
    NSUInteger tag = 0;
    for (SLHEncoderBaseFormat *fmt in _formats) {
        NSMenuItem *itm = [formatsMenu addItemWithTitle:fmt.formatName action:nil keyEquivalent:@""];
        itm.tag = tag++;
    }
    (void)x264Fmt.view;
    _encoderSettings.delegate = x264Fmt;
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
        [_metadataEditor reloadData];
    }
    [self _updatePopUpMenus:item];
}

#pragma mark - SLHMetadataEditor Delegate

- (NSDictionary *)dataForMetadataEditor:(SLHMetadataEditor *)editor {
    NSInteger row = _tableView.selectedRow;
    SLHEncoderItem *item = _arrayController.arrangedObjects[row];
    
    NSMutableDictionary *data = item.metadata.mutableCopy;
    if (data.count) {
        return data;
    } else {
        NSArray *array = item.mediaItem.metadata;
        for (SLHMetadataItem *m in array) {
            if ([m.identifier isEqual:SLHMetadataIdentifierArtist]) {
                data[SLHMetadataIdentifierArtist] = m.value;
            } else if ([m.identifier isEqual:SLHMetadataIdentifierTitle]) {
                data[SLHMetadataIdentifierTitle] = m.value;
            } else if ([m.identifier isEqual:SLHMetadataIdentifierDate]) {
                data[SLHMetadataIdentifierDate] = m.value;
            } else if ([m.identifier isEqual:SLHMetadataIdentifierComment]) {
                data[SLHMetadataIdentifierComment] = m.value;
            }
        }
    }
    if (!data.count) {  // No metadata
        data[SLHMetadataIdentifierTitle] = item.mediaItem.filePath.lastPathComponent.stringByDeletingPathExtension;
    }
    return data;
}

- (void)metadataEditor:(SLHMetadataEditor *)editor didEndEditing:(NSDictionary *)data {
    NSInteger row = _tableView.selectedRow;
    SLHEncoderItem *item = _arrayController.arrangedObjects[row];
    item.metadata = data.mutableCopy;
}

#pragma mark - SLHPlayer Delegate

- (void)player:(SLHPlayer *)p segmentStart:(double)start {
    if (!_tempEncoderItem || ![_arrayController.arrangedObjects containsObject:_tempEncoderItem]) {
        _tempEncoderItem = [self _createSegment];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [_arrayController addObject:_tempEncoderItem];
        });
    }
    _tempEncoderItem.intervalStart = start;
    
}

- (void)player:(SLHPlayer *)p segmentEnd:(double)end {
    _tempEncoderItem.intervalEnd = end;
}

- (void)playerDidEndEditingSegment:(SLHPlayer *)p {
    _tempEncoderItem = nil;
}

- (void)playerDidClearSegment:(SLHPlayer *)p {
    if (_tempEncoderItem) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [_arrayController removeObject:_tempEncoderItem];
        });
    }
        _tempEncoderItem = nil;
}

#pragma mark - SLHDragView Delegate

- (void)didReceiveFilename:(NSString *)filename {
    _currentMediaItem = [SLHMediaItem mediaItemWithPath:filename];
    if (_currentMediaItem.error) {
        NSLog(@"Error: %@", _currentMediaItem.error.localizedDescription);
        return;
    }
    [self _populatePopUpMenus:_currentMediaItem];
    [_arrayController removeObjects:_arrayController.arrangedObjects];
    _tempEncoderItem = nil;
    [self.window setTitleWithRepresentedFilename:_currentMediaItem.filePath];
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

#pragma mark - IBActions

- (IBAction)previewSourceFile:(id)sender {
    
    if (!_currentMediaItem) { // empty table
        NSBeep();
        return;
    }

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


- (IBAction)showMetadataEditor:(id)sender {
    
    if (!_tableView.numberOfRows) { // empty table
        NSBeep();
        return;
    }
    
    if (!_metadataEditor) {
        _metadataEditor = [[SLHMetadataEditor alloc] init];
        _metadataEditor.delegate = self;
    }
    [_metadataEditor showWindow:sender];
    [_metadataEditor reloadData];
}

- (IBAction)addEncoderItem:(id)sender {
    if (!_currentMediaItem) {
        NSBeep();
        return;
    }
    SLHEncoderItem *encItem = [self _createSegment];
    [_arrayController addObject:encItem];
}

- (IBAction)formatPopUpClicked:(id)sender {
    NSInteger tag = _formatsPopUp.selectedTag;
    SLHEncoderBaseFormat *fmt = _formats[tag];
    (void)fmt.view; // load view
    _encoderSettings.delegate = fmt;
    if (!_tableView.numberOfRows) { // empty table
        return;
    }
    NSInteger row = _tableView.selectedRow;
    SLHEncoderItem *item = _arrayController.arrangedObjects[row];
    item.tag = tag;
    fmt.encoderItem = item;
}

- (IBAction)selectOutputFileName:(id)sender {
    if (!_tableView.numberOfRows) {
        NSBeep();
        return;
    }
    
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
                item = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%lu: (%.0fx%.0f)", trackIndex, t.videoSize.width, t.videoSize.height] action:@selector(videoStreamPopUpAction:) keyEquivalent:@""];
                item.tag = trackIndex;
                item.target = self;
                [_videoStreamPopUp.menu addItem:item];
            }
                break;
            case SLHMediaTypeAudio:
            {
                item = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%lu: (%@, %@)", trackIndex, t.codecName, t.language] action:@selector(audioStreamPopUpAction:) keyEquivalent:@""];
                item.tag = trackIndex;
                item.target = self;
                [_audioStreamPopUp.menu addItem:item];
            }
                break;
            case SLHMediaTypeText:
            {
                item = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%lu: (%@)", trackIndex, t.language] action:@selector(subtitlesStreamPopUpAction:) keyEquivalent:@""];
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
    NSString *outputName = sourcePath.lastPathComponent.stringByDeletingPathExtension;
    outputPath = [NSString stringWithFormat:@"%@/%@_%lu%02u.%@", outputPath, outputName, time(0), arc4random_uniform(100), sourcePath.pathExtension];
    SLHEncoderItem *encoderItem = [[SLHEncoderItem alloc] initWithMediaItem:_currentMediaItem outputPath:outputPath];
    _outputFileNameTextField.stringValue = outputPath.lastPathComponent;
    encoderItem.interval = (TimeInterval){0, _currentMediaItem.duration};
    encoderItem.tag = _formatsPopUp.selectedTag;
    return encoderItem;
}


@end
