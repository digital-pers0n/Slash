//
//  SLKTabBarView.h
//  Slash
//
//  Created by Terminator on 2020/08/12.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SLKTabBarViewDelegate;

#pragma mark - SLKTabBarItem

@interface SLKTabBarItem : NSObject {
    @package
    NSButtonCell *_cell;
    NSString *_tooltip;
    NSRect _frame;
    NSInteger _tag;
}

- (instancetype)initWithIcon:(NSImage *)icon tooltip:(NSString *)tooltip;

@property (nonatomic, readonly) NSButtonCell *cell;
@property (nonatomic) NSString *tooltip;

@end

#pragma mark - SLKTabBarView

@interface SLKTabBarView : NSView

@property (nonatomic, weak) id<SLKTabBarViewDelegate> delegate;
@property (nonatomic, readonly) NSArray<SLKTabBarItem *> *items;
@property (nonatomic, readonly, nullable) SLKTabBarItem *selectedItem;
@property (nonatomic, readonly) NSInteger indexOfSelectedItem;

- (void)selectItemAtIndex:(NSInteger)idx;
- (void)addItems:(NSArray<SLKTabBarItem *> *)array;

@end

@protocol SLKTabBarViewDelegate <NSObject>

- (BOOL)tabBar:(SLKTabBarView *)tabBar shouldSelectItem:(SLKTabBarItem *)item;
- (void)tabBar:(SLKTabBarView *)tabBar didSelectItem:(SLKTabBarItem *)item;

@end

NS_ASSUME_NONNULL_END
