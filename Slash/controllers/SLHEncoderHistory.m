//
//  SLHEncoderHistory.m
//  Slash
//
//  Created by Terminator on 2020/01/06.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLHEncoderHistory.h"
#import "SLHExternalPlayer.h"

static NSString * const SLHEncoderHistoryPathsBinding = @"paths";

@interface SLHEncoderHistory () {
    IBOutlet NSArrayController *_arrayController;
    IBOutlet NSPopover *_popover;
    IBOutlet NSTextView *_logTextView;
    
    NSMutableDictionary *_items;
    NSMutableArray *_paths;
    
    SLHExternalPlayer *_player;
}

@property (nonatomic, readonly) NSMutableArray <NSString *> *paths;

@end

@implementation SLHEncoderHistory

- (NSString *)windowNibName {
    return self.className;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _paths = [NSMutableArray new];
        _items = [NSMutableDictionary new];
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    _popover.contentSize = NSMakeSize(480, 640);
}

- (void)addItemWithPath:(NSString *)path log:(NSString *)log {
    if (!_items[path]) {
        [self willChangeValueForKey:SLHEncoderHistoryPathsBinding];
        [_paths addObject:path];
        [self didChangeValueForKey:SLHEncoderHistoryPathsBinding];
    }
    _items[path] = log;
}

#pragma mark - IBActions

- (IBAction)removeSelected:(id)sender {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *selected = [_arrayController selectedObjects];
    int bypassTrash = NSApp.currentEvent.modifierFlags & NSEventModifierFlagOption;
    if (bypassTrash) {
        for (NSString *path in selected) {
            if (![fm removeItemAtPath:path error:&error]) {
                NSLog(@"error: %@", error.localizedDescription);
                [self presentError:error];
            }
        }
    } else {
        for (NSString *path in selected) {
            if (![fm trashItemAtURL:[NSURL fileURLWithPath:path isDirectory:NO] resultingItemURL:nil error:&error]) {
                NSLog(@"error: %@", error.localizedDescription);
                [self presentError:error];
            }
        }
    }
    [_arrayController removeObjects:selected];
    [_items removeObjectsForKeys:selected];
}

- (IBAction)previewSelected:(id)sender {
    NSString *path = _arrayController.selectedObjects.firstObject;
    if (path) {
        if (!_player) {
            _player = [SLHExternalPlayer defaultPlayer];
            if (_player.error) {
                [self presentError:_player.error];
                _player = nil;
                return;
            }
        }
        _player.url = [NSURL fileURLWithPath:path isDirectory:NO];
        [_player play];
        [_player orderFront];
    }
}

- (IBAction)revealSelected:(id)sender {
    NSString *path = _arrayController.selectedObjects.firstObject;
    if (path) {
        NSWorkspace *sharedWorkspace = [NSWorkspace sharedWorkspace];
        [sharedWorkspace selectFile:path inFileViewerRootedAtPath:@""];
    }
}

- (IBAction)showLog:(NSButton *)sender {
    if (_popover.shown) {
        [_popover close];
        return;
    }
    
    NSTableCellView *tcv = (id)sender.superview;
    NSString *path = tcv.objectValue;
    NSString *log = _items[path];
    _logTextView.string = log;
    [_logTextView scrollToEndOfDocument:nil];
    [_popover showRelativeToRect:sender.bounds ofView:sender preferredEdge:NSRectEdgeMinY];
}

@end
