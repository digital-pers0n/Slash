//
//  SLHMainWindowController.h
//  Slash
//
//  Created by Terminator on 2018/11/14.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class SLHMediaItem;

@interface SLHMainWindowController : NSWindowController

@property SLHMediaItem *currentMediaItem;
@property (readonly) NSString *lastEncodedMediaFilePath;
@property (readonly) BOOL hasSegments;

- (IBAction)previewSourceFile:(id)sender;
- (IBAction)previewSegment:(id)sender;
- (IBAction)previewOutputFile:(id)sender;
- (IBAction)updateSummary:(id)sender;

@end
