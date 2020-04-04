//
//  SLHTimelineView.h
//  Slash
//
//  Created by Terminator on 2020/04/03.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SLHTimelineViewDelegate;

@interface SLHTimelineView : NSView

@property (weak, nonatomic) IBOutlet NSView *documentView;
@property (weak, nonatomic) IBOutlet id<SLHTimelineViewDelegate> delegate;
@property (nonatomic) IBInspectable double doubleValue;
@property (nonatomic) IBInspectable double maxValue;
@property (nonatomic) IBInspectable double minValue;
@property (nonatomic) IBInspectable CGFloat indicatorMargin;

@end

@protocol SLHTimelineViewDelegate <NSObject>

- (void)timelineViewMouseDown:(SLHTimelineView *)timelineView;
- (void)timelineViewMouseUp:(SLHTimelineView *)timelineView;

@end

NS_ASSUME_NONNULL_END
