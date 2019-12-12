//
//  SLHTabBarView.h
//  Slash
//
//  Created by Terminator on 2018/11/08.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SLHTabBarViewDelegate;

@interface SLHTabBarView : NSView

@property (nullable, weak, nonatomic) IBOutlet id <SLHTabBarViewDelegate> delegate;
@property (nonatomic) NSUInteger selectedTabIndex;

@end

@protocol SLHTabBarViewDelegate <NSObject>

- (void)tabBarView:(SLHTabBarView *)tabBar didSelectTabAtIndex:(NSUInteger) tab;

@end

NS_ASSUME_NONNULL_END
