//
//  SLHEncoderSettings.m
//  Slash
//
//  Created by Terminator on 2018/11/13.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import "SLHEncoderSettings.h"
#import "SLHTabBarView.h"

@interface SLHEncoderSettings () <SLHTabBarViewDelegate> {
    IBOutlet SLHTabBarView *_tabBarView;
    IBOutlet NSScrollView *_scrollView;
    id <SLHEncoderSettingsDelegate> _delegate;
}

@end

@implementation SLHEncoderSettings

- (NSString *)nibName {
    return self.className;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)fitToWidth:(NSView *)view {
    NSRect frame = view.frame;
    frame.size.width = _scrollView.contentSize.width;
    view.frame = frame;
}

- (void)reloadTab {

    NSView *view = [_delegate encoderSettings:self viewForTab:_tabBarView.selectedTabIndex];
    if (view) {
        [self fitToWidth:view];
        _scrollView.documentView = view;
    }

}

#pragma mark - Properties

- (void)setDelegate:(id<SLHEncoderSettingsDelegate>)delegate {
    _delegate = delegate;
    [self reloadTab];
}

- (id<SLHEncoderSettingsDelegate>)delegate {
    return _delegate;
}

- (NSView *)selectedView {
    return _scrollView.documentView;
}

- (SLHEncoderSettingsTab)selectedTab {
    return _tabBarView.selectedTabIndex;
}

#pragma mark - SLHTabBarViewDelegate

- (void)tabBarView:(SLHTabBarView *)tabBar didSelectTabAtIndex:(NSUInteger)tab {
    NSView *view = [_delegate encoderSettings:self viewForTab:tab];
    [self fitToWidth:view];
    _scrollView.documentView = view;
}

@end
