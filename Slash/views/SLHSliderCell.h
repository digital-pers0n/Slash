//
//  SLHSliderCell.h
//  Slash
//
//  Created by Terminator on 2019/10/29.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SLHSliderCellMouseTrackingDelegate;

@interface SLHSliderCell : NSSliderCell

@property (nullable, weak) id <SLHSliderCellMouseTrackingDelegate> delegate;

@property (nonatomic, nonnull) NSColor *markColor;
@property (nonatomic, nonnull) NSColor *selectionColor;
@property (nonatomic) double inMark;
@property (nonatomic) double outMark;

@end

@protocol SLHSliderCellMouseTrackingDelegate <NSObject>

- (void)sliderCellMouseDown:(SLHSliderCell *)cell;
- (void)sliderCellMouseUp:(SLHSliderCell *)cell;
- (void)sliderCellMouseDragged:(SLHSliderCell *)cell;

@end


NS_ASSUME_NONNULL_END
