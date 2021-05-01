//
//  SLKTabBarView.m
//  Slash
//
//  Created by Terminator on 2020/08/12.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLKTabBarView.h"
#import "MPVKitDefines.h"

#pragma mark - SLKTabBarItem

@implementation SLKTabBarItem

- (instancetype)initWithIcon:(NSImage *)icon tooltip:(NSString *)tooltip {
    if (self = [super init]) {
        _tooltip = tooltip;
        _cell = [[NSButtonCell alloc] init];
        _cell.bordered = NO;
        [_cell setButtonType:NSButtonTypeToggle];
        _cell.image = icon;
    }
    return self;
}

- (instancetype)init {
    NSImage *icon = [NSImage imageNamed:NSImageNameActionTemplate];
    return [self initWithIcon:icon tooltip:@""];
}

@end

#pragma mark - SLKTabBarView

@interface SLKTabBarView () {
    const void **_cachedItems;
    NSMutableArray<SLKTabBarItem *> *_items;
    NSTrackingArea *_trackingArea;
    NSInteger _numberOfItems;
    NSInteger _indexOfSelectedItem;
    NSButtonCell *_highlightedCell;
}
- (void)commonInit OBJC_DIRECT;
@end

@implementation SLKTabBarView

- (void)commonInit {
    _items = [NSMutableArray array];
    _trackingArea = [[NSTrackingArea alloc] init];
    _cachedItems = malloc(sizeof(void*));
    _indexOfSelectedItem = NSNotFound;
}

- (void)addItems:(NSArray<SLKTabBarItem *> *)array {
    [_items addObjectsFromArray:array];
    CFIndex total = _items.count;
    if (total == 0) return; // ignore empty array
    free(_cachedItems);
    _cachedItems = malloc(sizeof(void*) * total);
    CFArrayGetValues((__bridge CFArrayRef)_items,
                     CFRangeMake(0, total), _cachedItems);
    _numberOfItems = total;
    SLKTabBarSetItemWidth(self, self.frame);
    self.needsDisplay = YES;
}

- (void)selectItemAtIndex:(NSInteger)idx {
    SLKTabBarSelectItem(self, _items[idx], idx);
}

static void SLKTabBarSelectItem(__unsafe_unretained SLKTabBarView *me,
                                __unsafe_unretained SLKTabBarItem *item,
                                NSInteger index) {
    id<SLKTabBarViewDelegate> delegate = me->_delegate;
    if ([delegate tabBar:me shouldSelectItem:item]) {
        if (me->_selectedItem) {
            me->_selectedItem->_cell.state = NSControlStateValueOff;
        }
        item->_cell.state = NSControlStateValueOn;
        me->_indexOfSelectedItem = index;
        me->_selectedItem = item;
        [delegate tabBar:me didSelectItem:item];
        me.needsDisplay = YES;
    }
}

static void SLKTabBarSetItemWidth(__unsafe_unretained SLKTabBarView *me,
                                  NSRect frame) {
    CGFloat itemWidth = NSWidth(frame) / me->_numberOfItems;
    NSRect itemFrame = NSMakeRect(0, 0, itemWidth, NSHeight(frame));
    __unsafe_unretained SLKTabBarItem *item;
    for (NSInteger i = 0; i < me->_numberOfItems; i++) {
        itemFrame.origin.x = itemWidth * i;
        item = (__bridge id)me->_cachedItems[i];
        item->_frame = itemFrame;
    }
}

#pragma mark - Overrides

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self commonInit];
    }
    return self;
}

- (void)dealloc {
    free(_cachedItems);
    [_items removeAllObjects];
}

- (void)setFrame:(NSRect)frame {
    if (_numberOfItems > 0) {
        SLKTabBarSetItemWidth(self, frame);
    }
    [super setFrame:frame];
}

- (void)drawRect:(NSRect)dirtyRect {
    __unsafe_unretained SLKTabBarItem *item;
    for (NSInteger i = 0; i < _numberOfItems; i++) {
        item = (__bridge id)_cachedItems[i];
        [item->_cell drawInteriorWithFrame:item->_frame inView:self];
    }
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    [self removeTrackingArea:_trackingArea];
    NSTrackingAreaOptions opts;
    opts = NSTrackingActiveInActiveApp | NSTrackingMouseEnteredAndExited
           | NSTrackingInVisibleRect | NSTrackingMouseMoved;
    _trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:opts
                                                   owner:self userInfo:nil];
    [self addTrackingArea:_trackingArea];
}

- (void)mouseMoved:(NSEvent *)event {
    NSPoint point = [self convertPoint:event.locationInWindow fromView:nil];
    __unsafe_unretained SLKTabBarItem *item;
    for (NSInteger i = 0; i < _numberOfItems; i++) {
        item = (__bridge id)_cachedItems[i];
        if (NSMouseInRect(point, item->_frame, /* flipped */ NO)) {
            self.toolTip = nil;
            self.toolTip = item->_tooltip;

            if (item->_cell == _highlightedCell) {
                break;
            }
            if (_highlightedCell) {
                _highlightedCell.highlighted = NO;
            }
            item->_cell.highlighted = YES;
            _highlightedCell = item->_cell;
            self.needsDisplay = YES;
            break;
        }
    }
}

- (void)mouseExited:(NSEvent *)event {
    if (_highlightedCell) {
        _highlightedCell.highlighted = NO;
        _highlightedCell = nil;
        self.needsDisplay = YES;
    }
}

- (void)mouseUp:(NSEvent *)event {
    NSPoint point = [self convertPoint:event.locationInWindow fromView:nil];
    __unsafe_unretained SLKTabBarItem *item;
    for (NSInteger i = 0; i < _numberOfItems; i++) {
        item = (__bridge id)_cachedItems[i];
        if ([self mouse:point inRect:item->_frame]) {
            if (i == _indexOfSelectedItem) {
                break;
            }
            SLKTabBarSelectItem(self, item, i);
            break;
        }
    }
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event {
    return YES;
}

- (BOOL)isFlipped {
    return NO;
}

@end
