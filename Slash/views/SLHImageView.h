//
//  SLHImageView.h
//  Slash
//
//  Created by Terminator on 2019/03/27.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

@import Quartz;

@protocol SLHImageViewDelegate;

@interface IKImageView (Private)

/* methods from the ImageKit class-dump */
- (NSRect)selectionRect;
- (void)setSelectionRect:(NSRect)rect;
- (IBAction)showInspector:(id)sender;
- (IBAction)closeInspector:(id)sender;

@end

@interface SLHImageView : IKImageView

@property (assign) id <SLHImageViewDelegate> delegate;

@end

@protocol SLHImageViewDelegate <NSObject>

- (void)imageView:(SLHImageView *)view didUpdateSelection:(NSRect)rect;

@end

