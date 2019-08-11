//
//  SLHMainWindowController.h
//  Slash
//
//  Created by Terminator on 2018/11/14.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class SLHMediaItem, SLHEncoderQueue;

@interface SLHMainWindowController : NSWindowController

@property SLHMediaItem *currentMediaItem;
@property (readonly) NSString *lastEncodedMediaFilePath;
@property (readonly) BOOL hasSegments;
@property (readonly) SLHEncoderQueue *queue;

- (IBAction)previewSourceFile:(id)sender;
- (IBAction)previewSegment:(id)sender;
- (IBAction)previewOutputFile:(id)sender;
- (IBAction)updateSummary:(id)sender;
- (IBAction)updateOutputFileName:(id)sender;
- (IBAction)startEncoding:(id)sender;
- (IBAction)addToQueue:(id)sender;
- (IBAction)showQueue:(id)sender;
- (IBAction)showMetadataEditor:(id)sender;
- (IBAction)savePreset:(id)sender;
- (IBAction)showPresetsWindow:(id)sender;

@end
