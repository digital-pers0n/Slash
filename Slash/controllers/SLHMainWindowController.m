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

@interface SLHMainWindowController () <SLHDragViewDelegate> {
    SLHDragView *_dragView;
    SLHEncoderSettings *_encoderSettings;
    IBOutlet NSView *_customView;
    IBOutlet NSArrayController *_arrayController;
    IBOutlet NSTableView *_tableView;
    IBOutlet NSPopUpButton *_formatsPopUp;
    
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
}

#pragma mark - SLHDragView Delegate

- (void)didReceiveFilename:(NSString *)filename {
    SLHMediaItem *mediaItem = [SLHMediaItem mediaItemWithPath:filename];
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
    
}
- (void)didEndDraggingSession {
    
}
- (void)didReceiveMouseEvent:(NSEvent *)event {
    
}

@end
