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

#import "MPVPlayer.h"
#import "MPVPlayerItem.h"
#import "MPVPlayerItemTrack.h"

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

- (IBAction)videoStreamPopUpAction:(NSMenuItem *)sender {
    _currentEncoderItem.videoStreamIndex = sender.tag;
}

- (IBAction)audioStreamPopUpAction:(NSMenuItem *)sender {
    _currentEncoderItem.audioStreamIndex = sender.tag;
}

- (IBAction)subtitlesStreamPopUpAction:(NSMenuItem *)sender {
    _currentEncoderItem.subtitlesStreamIndex = sender.tag;
}

- (IBAction)formatsPopUpAction:(id)sender {
    SLHEncoderBaseFormat * encoderFormat = _formatsArrayController.selectedObjects.firstObject;
    SLHEncoderItem *encoderItem = _itemsArrayController.selectedObjects.firstObject;
    encoderFormat.encoderItem = encoderItem;
    encoderItem.tag = _formatsArrayController.selectionIndex;
    _encoderSettings.delegate = encoderFormat;
    encoderFormat.view.needsDisplay = YES;
}

- (IBAction)showTextEditor:(NSButton *)sender {

}

- (IBAction)selectOutputPath:(NSButton *)sender {

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
        MPVPlayerItem *item = [MPVPlayerItem playerItemWithPath:path];
        if (item.error) {
            [NSApp presentError:item.error];
            return NO;
        }
        _playerView.player.currentItem = item;
        SLHEncoderItem *encoderItem = [[SLHEncoderItem alloc] initWithPlayerItem:item];
        self.currentEncoderItem = encoderItem;
        [_itemsArrayController addObject:encoderItem];
        [encoderItem matchSource];
        [self populatePopUpMenus:item];
        result = YES;
    }
    return result;
}

#pragma mark - NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
     SLHEncoderItem *encoderItem = _itemsArrayController.selectedObjects.firstObject;
    [_formatsArrayController setSelectionIndex:encoderItem.tag];
    SLHEncoderBaseFormat *fmt = _formatsArrayController.selectedObjects.firstObject;
    fmt.encoderItem = encoderItem;
    _encoderSettings.delegate = fmt;
    
    MPVPlayer *player = _playerView.player;
    player.currentItem = encoderItem.playerItem;
    [player pause];
    
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
