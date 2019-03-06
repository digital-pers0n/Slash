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
#import "SLHMetadataIdentifiers.h"
#import "SLHEncoderBaseFormat.h"
#import "SLHEncoderX264Format.h"

@interface SLHMainWindowController () <SLHDragViewDelegate, SLHMetadataEditorDelegate, NSTableViewDelegate> {
    SLHDragView *_dragView;
    SLHEncoderSettings *_encoderSettings;
    SLHMetadataEditor *_metadataEditor;
    NSArray <SLHEncoderBaseFormat *> *_formats;
    
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
}

#pragma mark - NSTableView Delegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger row = _tableView.selectedRow;
    SLHEncoderItem *item = _arrayController.arrangedObjects[row];
    [self.window setTitleWithRepresentedFilename:item.mediaItem.filePath];
}

#pragma mark - SLHMetadataEditor Delegate

- (NSMutableDictionary *)dataForMetadataEditor:(SLHMetadataEditor *)editor {
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

- (void)metadataEditor:(SLHMetadataEditor *)editor didEndEditing:(NSMutableDictionary *)data {
    NSInteger row = _tableView.selectedRow;
    SLHEncoderItem *item = _arrayController.arrangedObjects[row];
    item.metadata = data.mutableCopy;
}

#pragma mark - SLHDragView Delegate

- (void)didReceiveFilename:(NSString *)filename {
    SLHMediaItem *mediaItem = [SLHMediaItem mediaItemWithPath:filename];
    if (mediaItem.error) {
        NSLog(@"Error: %@", mediaItem.error.localizedDescription);
        return;
    }
    [self _populatePopUpMenus:mediaItem];
    NSString *outputPath = nil;
    SLHPreferences *prefs = [SLHPreferences preferences];
    if (prefs.outputPathSameAsInput) {
        outputPath = [filename stringByDeletingLastPathComponent];
    } else {
        outputPath = prefs.currentOutputPath;
    }
    NSString *outputName = filename.lastPathComponent.stringByDeletingPathExtension;
    outputPath = [NSString stringWithFormat:@"%@/%@_%lu.%@", outputPath, outputName, time(0), filename.pathExtension];
    SLHEncoderItem *encItem = [[SLHEncoderItem alloc] initWithMediaItem:mediaItem outputPath:outputPath];
    _outputFileNameTextField.stringValue = outputPath.lastPathComponent;
    encItem.interval = (TimeInterval){0, mediaItem.duration};
    [_arrayController addObject:encItem];
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
    
}

- (IBAction)formatPopUpClicked:(id)sender {
    SLHEncoderBaseFormat *fmt = _formats[_formatsPopUp.selectedTag];
    (void)fmt.view; // load view
    NSInteger row = _tableView.selectedRow;
    SLHEncoderItem *item = _arrayController.arrangedObjects[row];
    fmt.encoderItem = item;
    _encoderSettings.delegate = fmt;
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
    [_videoStreamPopUp.menu addItem:item];
    item.action = @selector(audioStreamPopUpAction:);
    [_audioStreamPopUp.menu addItem:item.copy];
    item.action = @selector(subtitlesStreamPopUpAction:);
    [_subtitlesStreamPopUp.menu addItem:item.copy];
}


@end
