//
//  SLHEncoderQueue.m
//  Slash
//
//  Created by Terminator on 2019/04/03.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHEncoderQueue.h"
#import "SLHArgumentsViewController.h"
#import "SLHEncoderItem.h"
#import "SLHMediaItem.h"
#import "SLHMediaItemTrack.h"
#import "SLHEncoderQueueItem.h"

@interface SLHEncoderQueue () <NSTableViewDelegate, NSSplitViewDelegate> {
    
    IBOutlet NSView *_customView;
    IBOutlet SLHArgumentsViewController *_argumentsViewController;
    IBOutlet NSTableView *_tableView;
    IBOutlet NSArrayController *_arrayController;
    IBOutlet NSSplitView *_splitView;
}

@property BOOL inProgress;

@end

@implementation SLHEncoderQueue

- (NSString *)windowNibName {
    return self.className;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    NSRect rect = _customView.frame;
    NSView *view =  _argumentsViewController.view;
    view.frame = rect;
    [_splitView replaceSubview:_customView with:view];
}

- (void)addEncoderItems:(NSArray<SLHEncoderItem *> *)array {
    [self.window makeKeyAndOrderFront:nil];
    NSMutableArray *objects = [NSMutableArray arrayWithCapacity:array.count];
    NSUInteger tag = [_arrayController.arrangedObjects count];
    
    for (SLHEncoderItem *i in array) {
        SLHEncoderQueueItem *obj = [SLHEncoderQueueItem new];
        obj.encoderArguments = i.encoderArguments;
        obj.name = i.outputPath;
        
        NSInteger streamIdx = i.videoStreamIndex;
        if (streamIdx > -1) {
            TimeInterval interval = i.interval;
            SLHMediaItemTrack *t = i.mediaItem.tracks[streamIdx];
            obj.numberOfFrames = (interval.end - interval.start) * t.frameRate;
        }
        obj.tag = tag++;
        [objects addObject:obj];
    }
    [_arrayController addObjects:objects];
    /* Avoid a bug when NSArrayController sends tableViewSelectionDidChange: messages to a delegate
       even if the selection is empty. The bug occurs if the allowsEmptySelection property was set to NO in the Interface Builder */
    [_tableView setAllowsEmptySelection:NO];
}

#pragma mark - IBActions

- (IBAction)startEncoding:(id)sender {
}

- (IBAction)pauseEncoding:(id)sender {
}

- (IBAction)stopEncoding:(id)sender {
}

- (IBAction)removeAll:(id)sender {
}

#pragma mark - NSSplitViewDelegate

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {
    if (subview == _argumentsViewController.view) {
        return YES;
    }
    return NO;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex {
    return NSWidth(splitView.frame) - 285;
}

#pragma mark - NSTableView Delegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger row = _tableView.selectedRow;
    id item = _arrayController.arrangedObjects[row];
    _argumentsViewController.encoderItem = item;
}


@end
