//
//  SLHMetadataEditor.h
//  Slash
//
//  Created by Terminator on 2019/03/04.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SLHMetadataEditorDelegate;

@interface SLHMetadataEditor : NSWindowController

@property (nullable) IBOutlet id <SLHMetadataEditorDelegate> delegate;
- (void)reloadData;

@end

@protocol SLHMetadataEditorDelegate <NSObject>

- (NSDictionary *)dataForMetadataEditor:(SLHMetadataEditor *)editor;
- (void)metadataEditor:(SLHMetadataEditor *)editor didEndEditing:(NSDictionary *)data;

@end

NS_ASSUME_NONNULL_END