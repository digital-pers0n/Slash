//
//  SLHDragView.h
//  Slash
//
//  Created by Terminator on 2018/07/18.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol SLHDragViewDelegate;

@interface SLHDragView : NSView

@property id <SLHDragViewDelegate> delegate;

@end

@protocol SLHDragViewDelegate <NSObject>

- (void)didReceiveFilename:(NSString *)filename;
- (void)didBeginDraggingSession;
- (void)didEndDraggingSession;
- (void)didReceiveMouseEvent:(NSEvent *)event;

@end