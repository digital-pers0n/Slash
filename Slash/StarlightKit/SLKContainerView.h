//
//  SLKContainerView.h
//  Slash
//
//  Created by Terminator on 2020/10/13.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SLKContainerViewDelegate;

@interface SLKContainerView : NSView

@property (nonatomic, weak) IBOutlet id<SLKContainerViewDelegate> delegate;

@end

@protocol SLKContainerViewDelegate

- (void)viewWillStartLiveResize:(SLKContainerView *)view;
- (void)viewDidEndLiveResize:(SLKContainerView *)view;

@end

NS_ASSUME_NONNULL_END
