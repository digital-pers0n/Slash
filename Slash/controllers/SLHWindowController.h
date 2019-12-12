//
//  SLHWindowController.h
//  Slash
//
//  Created by Terminator on 2019/09/01.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class SLHEncoderQueue, SLHEncoderItem;

@interface SLHWindowController : NSWindowController


@property (readonly, nonatomic, nullable) SLHEncoderItem * currentEncoderItem;
@property (readonly, nonatomic, nullable) NSString *lastEncodedMediaFilePath;
@property (readonly, nonatomic) SLHEncoderQueue *queue;

- (BOOL)loadFileURL:(NSURL *)url;

@property (readonly, nonatomic, getter=isSideBarHidden) BOOL sideBarHidden;

- (IBAction)previewSourceFile:(id)sender;
- (IBAction)previewSegment:(id)sender;
- (IBAction)previewOutputFile:(id)sender;
- (IBAction)updateOutputFileName:(id)sender;
- (IBAction)startEncoding:(id)sender;
- (IBAction)addSelectionToQueue:(id)sender;
- (IBAction)addAllToQueue:(id)sender;
- (IBAction)showQueue:(id)sender;
- (IBAction)savePreset:(id)sender;
- (IBAction)showPresetsWindow:(id)sender;

@end

NS_ASSUME_NONNULL_END
