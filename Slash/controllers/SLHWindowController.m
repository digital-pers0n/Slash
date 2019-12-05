//
//  SLHWindowController.m
//  Slash
//
//  Created by Terminator on 2019/09/01.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHWindowController.h"
#import "SLHPlayerView.h"
#import "SLHEncoderItem.h"
#import "SLHEncoderItemOptions.h"
#import "SLHEncoderSettings.h"
#import "SLHPreferences.h"
#import "SLHTextEditor.h"

#import "MPVPlayer.h"
#import "MPVPlayerItem.h"
#import "MPVPlayerItemTrack.h"
#import "MPVPlayerProperties.h"

#import "SLHEncoderVP9Format.h"
#import "SLHEncoderVPXFormat.h"
#import "SLHEncoderX264Format.h"
#import "SLHEncoderUniversalFormat.h"

@interface SLHWindowController () <NSSplitViewDelegate, NSWindowDelegate, NSDraggingDestination, NSTableViewDelegate> {
    IBOutlet SLHPlayerView *_playerView;
    IBOutlet NSView *_sbView;
    IBOutlet NSView *_bottomBarView;
    IBOutlet NSArrayController *_itemsArrayController;
    IBOutlet NSArrayController *_formatsArrayController;
    IBOutlet NSSplitView *_inspectorSplitView;
    IBOutlet NSSplitView *_videoSplitView;
    
    IBOutlet NSPopUpButton *_videoStreamPopUp;
    IBOutlet NSPopUpButton *_audioStreamPopUp;
    IBOutlet NSPopUpButton *_subtitlesStreamPopUp;
    IBOutlet NSPopUpButton *_formatsPopUp;
    
    SLHEncoderSettings *_encoderSettings;
    SLHTextEditor *_textEditor;
    NSPopover *_popover;
    
    CGFloat _sideBarWidth;
    CGFloat _bottomBarHeight;
}

@property (nonatomic) SLHEncoderItem *currentEncoderItem;

@end

@implementation SLHWindowController

- (NSString *)windowNibName {
    return self.className;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    /* SLHEncoderSettings */
    _encoderSettings = [[SLHEncoderSettings alloc] init];
    _encoderSettings.view.autoresizingMask = _sbView.autoresizingMask;
    _encoderSettings.view.frame = _sbView.frame;

    [_sbView.superview replaceSubview:_sbView with:_encoderSettings.view];
    
    _sideBarWidth = NSWidth(_sbView.frame);
    _bottomBarHeight = NSHeight(_bottomBarView.frame);
    self.window.delegate = self;
    
    /* SLHFormat */
    SLHEncoderX264Format *x264Fmt = [[SLHEncoderX264Format alloc] init];
    SLHEncoderVPXFormat *vpxFmt = [[SLHEncoderVPXFormat alloc] init];
    SLHEncoderVP9Format *vp9Fmt = [[SLHEncoderVP9Format alloc] init];
    SLHEncoderUniversalFormat *uniFmt = [[SLHEncoderUniversalFormat alloc] init];
    
    NSArray *_formats = @[x264Fmt, vpxFmt, vp9Fmt, uniFmt];
    [_formatsArrayController addObjects:_formats];
    NSString *name = SLHPreferences.preferences.lastUsedFormatName;
    if (name) {
        [_formatsPopUp selectItemWithTitle:name];
    }
    
    [self formatsPopUpAction:_formatsPopUp];
    
    /* Drag and Drop support */
    [self.window registerForDraggedTypes:@[NSFilenamesPboardType]];
    
    /* MPVPlayer */
    MPVPlayer *player = [[MPVPlayer alloc] init];
    _playerView.player = player;
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(playerDidLoadFile:) name:MPVPlayerDidLoadFileNotification object:player];

}

#pragma mark - Methods

- (BOOL)hasMediaStreams:(MPVPlayerItem *)playerItem {
    for (MPVPlayerItemTrack * track in playerItem.tracks) {
        switch (track.mediaType) {
                
            case MPVMediaTypeVideo:
            case MPVMediaTypeAudio:
                
                return YES;
                
                break;
                
            default:
                break;
        }
    }
    
    return NO;
}

- (NSString *)outputPathForSourcePath:(NSString *)sourcePath {
    NSString *outputPath = nil;
    SLHPreferences *prefs = [SLHPreferences preferences];
    if (prefs.outputPathSameAsInput) {
        outputPath = [sourcePath stringByDeletingLastPathComponent];
    } else {
        outputPath = prefs.currentOutputPath;
    }
    return outputPath;
}

#pragma mark - PopUp Menus

- (void)populatePopUpMenus:(MPVPlayerItem *)playerItem {
    NSMenuItem *item;
    [_videoStreamPopUp removeAllItems];
    [_audioStreamPopUp removeAllItems];
    [_subtitlesStreamPopUp removeAllItems];
    
    for (MPVPlayerItemTrack *t in playerItem.tracks) {
        NSUInteger trackIndex = t.trackIndex;
        switch (t.mediaType) {
            case MPVMediaTypeVideo:
            {
                NSSize videoSize = t.videoSize;
                NSSize codedVideoSize = t.codedVideoSize;
                NSString *videoSizeString = [NSString stringWithFormat:@"%.0fx%.0f", videoSize.width, videoSize.height];
                if (videoSize.width != codedVideoSize.width ||
                    videoSize.height != codedVideoSize.height) {
                    videoSizeString = [NSString stringWithFormat:@"%@ (coded %.0fx%.0f)", videoSizeString, codedVideoSize.width, codedVideoSize.height];
                }
                
                item = [[NSMenuItem alloc] initWithTitle:
                        [NSString stringWithFormat:@"%lu: %@, %@ [SAR %.0f:%.0f, DAR %.0f:%.f], %g fps, %g tbr",
                         trackIndex,
                         t.codecName,
                         videoSizeString,
                         t.sampleAspectRatio.width,
                         t.sampleAspectRatio.height,
                         t.displayAspectRatio.width,
                         t.displayAspectRatio.height,
                         t.averageFrameRate,
                         t.realBaseFrameRate]
                                                  action:@selector(videoStreamPopUpAction:)
                                           keyEquivalent:@""];
                item.tag = trackIndex;
                item.target = self;
                [_videoStreamPopUp.menu addItem:item];
            }
                break;
            case MPVMediaTypeAudio:
            {
                item = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%lu: %@, %@, %@, %llukbs", trackIndex, t.codecName, t.language, t.channelLayout, t.bitRate / 1000] action:@selector(audioStreamPopUpAction:) keyEquivalent:@""];
                item.tag = trackIndex;
                item.target = self;
                [_audioStreamPopUp.menu addItem:item];
            }
                break;
            case MPVMediaTypeText:
            {
                item = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%lu: %@, %@", trackIndex, t.language, t.codecName] action:@selector(subtitlesStreamPopUpAction:) keyEquivalent:@""];
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



- (void)updatePopUpMenus:(SLHEncoderItem *)item {
    [_videoStreamPopUp selectItemWithTag:item.videoStreamIndex];
    [_audioStreamPopUp selectItemWithTag:item.audioStreamIndex];
    [_subtitlesStreamPopUp selectItemWithTag:item.subtitlesStreamIndex];
}

#pragma mark - IBActions

// TODO: allow to open files from disk
- (IBAction)addEncoderItem:(id)sender {
    if (_currentEncoderItem) {
        SLHEncoderItem *encoderItem = _currentEncoderItem.copy;
        NSString *extension = encoderItem.outputPath.pathExtension;
        NSString *fileName = encoderItem.playerItem.url.lastPathComponent.stringByDeletingPathExtension;
        encoderItem.outputFileName = [fileName stringByAppendingFormat:@"_%lu%02u.%@", time(0), arc4random_uniform(100), extension];
        [_itemsArrayController insertObject:encoderItem
                      atArrangedObjectIndex:[_itemsArrayController.arrangedObjects indexOfObject:_currentEncoderItem] + 1];
        
        // Force Key-Value observer to update
        encoderItem.intervalStart = _currentEncoderItem.interval.start;
        
    } else {
        NSBeep();
        /*
        [NSApp.delegate performSelector:@selector(openDocument:) withObject:nil];
         */
    }
}

- (IBAction)removeEncoderItem:(id)sender {
    [_itemsArrayController remove:sender];
    if (!_itemsArrayController.canRemove) {
        self.currentEncoderItem = nil;
        _playerView.player.currentItem = nil;
        [_formatsArrayController.selection setValue:nil forKey:@"encoderItem"];
        NSWindow *window = self.window;
        window.representedURL = nil;
        window.title = @"";
        [_encoderSettings reloadTab];
        [_videoStreamPopUp removeAllItems];
        [_audioStreamPopUp removeAllItems];
        [_subtitlesStreamPopUp removeAllItems];
    }
}

- (IBAction)videoStreamPopUpAction:(NSMenuItem *)sender {
    NSInteger tag = sender.tag;
    _currentEncoderItem.videoStreamIndex = tag;
    
    if (tag == -1) {
        [_playerView.player setBool:NO
                          forProperty:MPVPlayerPropertyVideoID];
    } else {
        [_playerView.player setInteger:[sender.menu indexOfItem:sender] + 1
                           forProperty:MPVPlayerPropertyVideoID];
    }
}

- (IBAction)audioStreamPopUpAction:(NSMenuItem *)sender {
    NSInteger tag = sender.tag;
    _currentEncoderItem.audioStreamIndex = tag;
    
    if (tag == -1) {
        [_playerView.player setBool:NO
                          forProperty:MPVPlayerPropertyAudioID];
    } else {
        [_playerView.player setInteger:[sender.menu indexOfItem:sender] + 1
                           forProperty:MPVPlayerPropertyAudioID];
    }
}

- (IBAction)subtitlesStreamPopUpAction:(NSMenuItem *)sender {
    NSInteger tag = sender.tag;
    _currentEncoderItem.subtitlesStreamIndex = tag;
    
    if (tag == -1) {
        [_playerView.player setBool:NO
                          forProperty:MPVPlayerPropertySubtitleID];
    } else {
        [_playerView.player setInteger:[sender.menu indexOfItem:sender] + 1
                           forProperty:MPVPlayerPropertySubtitleID];
    }
}

- (IBAction)formatsPopUpAction:(id)sender {
    SLHEncoderBaseFormat * encoderFormat = _formatsArrayController.selectedObjects.firstObject;
    SLHEncoderItem *encoderItem = _itemsArrayController.selectedObjects.firstObject;
    encoderFormat.encoderItem = encoderItem;
    encoderItem.tag = _formatsArrayController.selectionIndex;
    _encoderSettings.delegate = encoderFormat;
    encoderFormat.view.needsDisplay = YES;
}

- (IBAction)textEditorDone:(id)sender {
    NSString *outPath = _textEditor.textView.string.copy;
    SLHEncoderItem *encoderItem = _textEditor.representedObject;
    
    [encoderItem willChangeValueForKey:@"outputFileName"];
    {
        encoderItem.outputPath = outPath;
    }
    [encoderItem didChangeValueForKey:@"outputFileName"];
    
    [_popover close];
    _textEditor.representedObject = nil;
}

- (IBAction)textEditorCancel:(id)sender {
     [_popover close];
    _textEditor.representedObject = nil;
}

- (IBAction)showTextEditor:(NSButton *)sender {
    
    if (!_popover) {
        _textEditor = SLHTextEditor.new;
        NSRect frame = NSMakeRect(0, 0, 500, 200);
        _textEditor.view.frame = frame;
        NSButton *button = _textEditor.doneButton;
        button.action = @selector(textEditorDone:);
        button.target = self;
        button = _textEditor.cancelButton;
        button.action = @selector(textEditorCancel:);
        button.target = self;
        _popover = NSPopover.new;
        _popover.contentViewController = _textEditor;
    }
    
    NSTableCellView *tableCell = (id)sender.superview;
    SLHEncoderItem *encoderItem = tableCell.objectValue;
    _textEditor.representedObject = encoderItem;
    NSString *outPath = encoderItem.outputPath;
    _textEditor.textView.string = outPath;
    [_popover showRelativeToRect:sender.frame ofView:sender.superview preferredEdge:NSMinYEdge];

}

- (IBAction)selectOutputPath:(NSButton *)sender {
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = NO;
    panel.canChooseFiles = NO;
    panel.canChooseDirectories = YES;
    panel.canCreateDirectories = YES;
    NSModalResponse returnCode = [panel runModal];
    
    if (returnCode == NSModalResponseOK) {
        
        NSString *path = panel.URL.path;
        NSTableCellView *tableCell = (id)sender.superview;
        SLHEncoderItem *encoderItem = tableCell.objectValue;
        NSString *outname = encoderItem.outputPath.lastPathComponent;
        encoderItem.outputPath = [NSString stringWithFormat:@"%@/%@", path, outname];
    }
}

#pragma mark - MPVPlayer Notifications

- (void)playerDidLoadFile:(NSNotification *)n {
    _playerView.player.timePosition = _currentEncoderItem.interval.start;
}

#pragma mark - NSDraggingDestination

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    
    if ([pboard.types containsObject:NSFilenamesPboardType] && sourceDragMask & NSDragOperationGeneric) {
        return NSDragOperationGeneric;
    }
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    BOOL result = NO;
    
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    
    if ([pboard.types containsObject:NSFilenamesPboardType] && sourceDragMask & NSDragOperationGeneric) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        NSString * path = files.firstObject;
        MPVPlayerItem *playerItem = [MPVPlayerItem playerItemWithPath:path];
        if (playerItem.error) {
            [NSApp presentError:playerItem.error];
            return NO;
        }
        
        if (![self hasMediaStreams:playerItem]) {
            NSAlert *alert = [NSAlert new];
            alert.messageText = [NSString stringWithFormat:@"Cannot load %@", path];
            alert.informativeText = @"File doesn't not contain playable streams.";
            [alert runModal];
            return NO;
        }
        
        _playerView.player.currentItem = playerItem;
        SLHEncoderItem *encoderItem = [[SLHEncoderItem alloc] initWithPlayerItem:playerItem];
        NSString *outputName = encoderItem.outputFileName;
        encoderItem.outputPath = [[self outputPathForSourcePath:playerItem.filePath] stringByAppendingPathComponent:outputName];
        
        [encoderItem matchSource];
        [self populatePopUpMenus:playerItem];
        [self updatePopUpMenus:encoderItem];
        [self updateWindowTitle:playerItem.url];
        
        [_itemsArrayController addObject:encoderItem];
        
        result = YES;
    }
    return result;
}

- (void)updateWindowTitle:(NSURL *)url {
    NSWindow *window = self.window;
    window.title = url.lastPathComponent;
    window.representedURL = url;
}

#pragma mark - NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
     SLHEncoderItem *encoderItem = _itemsArrayController.selectedObjects.firstObject;
    
    /* Check if already selected */
    if (encoderItem == _currentEncoderItem) {
        return;
    }
    
    [_formatsArrayController setSelectionIndex:encoderItem.tag];
    SLHEncoderBaseFormat *fmt = _formatsArrayController.selectedObjects.firstObject;
    fmt.encoderItem = encoderItem;
    _encoderSettings.delegate = fmt;
    
    MPVPlayer *player = _playerView.player;
    MPVPlayerItem *playerItem = encoderItem.playerItem;
    if (playerItem != _currentEncoderItem.playerItem) {
        
        player.currentItem = playerItem;
        [player pause];
        [self populatePopUpMenus:playerItem];
        [self updateWindowTitle:playerItem.url];
    }
    
    self.currentEncoderItem = encoderItem;
    [self updatePopUpMenus:encoderItem];
}

#pragma mark - NSWindowDelegate

- (void)windowWillStartLiveResize:(NSNotification *)notification {
    _sideBarWidth = NSWidth(_encoderSettings.view.frame);
    _bottomBarHeight = NSHeight(_bottomBarView.frame);
}

- (void)windowDidResize:(NSNotification *)notification {
    [_inspectorSplitView setPosition:NSWidth(_inspectorSplitView.frame) - _sideBarWidth ofDividerAtIndex:0];
    [_videoSplitView setPosition:NSHeight(_videoSplitView.frame) - _bottomBarHeight ofDividerAtIndex:0];
}

- (void)windowDidEndLiveResize:(NSNotification *)notification {
    [_inspectorSplitView setPosition:NSWidth(_inspectorSplitView.frame) - _sideBarWidth ofDividerAtIndex:0];
}

- (void)windowWillEnterFullScreen:(NSNotification *)notification {
    _sideBarWidth = NSWidth(_encoderSettings.view.frame);
    _bottomBarHeight = NSHeight(_bottomBarView.frame);
}

- (void)windowDidEnterFullScreen:(NSNotification *)notification {
    [_inspectorSplitView setPosition:NSWidth(_inspectorSplitView.frame) - _sideBarWidth ofDividerAtIndex:0];
    [_videoSplitView setPosition:NSHeight(_videoSplitView.frame) - _bottomBarHeight ofDividerAtIndex:0];
}

- (void)windowWillExitFullScreen:(NSNotification *)notification {
    _sideBarWidth = NSWidth(_encoderSettings.view.frame);
    _bottomBarHeight = NSHeight(_bottomBarView.frame);
}

- (void)windowDidExitFullScreen:(NSNotification *)notification {
    [_inspectorSplitView setPosition:NSWidth(_inspectorSplitView.frame) - _sideBarWidth ofDividerAtIndex:0];
    [_videoSplitView setPosition:NSHeight(_videoSplitView.frame) - _bottomBarHeight ofDividerAtIndex:0];
}

#pragma mark - NSSplitViewDelegate

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {
    return NO;
}
- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)view {
    return NO;
}

//#if 0

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex {
    if (splitView == _inspectorSplitView) {
        return NSWidth(splitView.frame) - 200;
    }
    return NSHeight(splitView.frame) - 100;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex {
    if (splitView == _inspectorSplitView) {
        return NSWidth(splitView.frame) - 260;
    }
    return NSHeight(splitView.frame) - 220;
}

//#endif

#if 0
- (CGFloat)splitView:(NSSplitView *)splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex {
    
    NSRect frame = splitView.frame;
    
    if (splitView == _inspectorSplitView) {
        CGFloat minPosition = NSWidth(frame) - 200;
        CGFloat maxPostion = NSWidth(frame) - 260;
        if (proposedPosition > minPosition) {
            return minPosition;
        }
        
        if (proposedPosition < maxPostion) {
            return maxPostion;
        }
        
        return proposedPosition;
        
    } else {
        CGFloat minPosition = NSHeight(frame) - 100;
        CGFloat maxPostion = NSHeight(frame) - 220;
        
        if (proposedPosition > minPosition) {
            return minPosition;
        }
        
        if (proposedPosition < maxPostion) {
            return maxPostion;
        }
        return proposedPosition;
    }
    
    return proposedPosition;
}
#endif

@end
