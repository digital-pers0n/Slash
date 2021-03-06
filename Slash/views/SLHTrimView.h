//
//  SLHTrimView.h
//  Slash
//
//  Created by Terminator on 2019/11/05.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

static const CGFloat SLHTrimViewHandleThickness =  10.0;

@protocol SLHTrimViewDelegate;

@interface SLHTrimView : NSView

@property (nonatomic, weak) IBOutlet id <SLHTrimViewDelegate> delegate;

/**
 @discussion a trim view's tool tip formatter
 */
@property (nullable, strong) IBOutlet NSFormatter *formatter;

/** 
 @discussion Must be greater than 0.
 */
@property (nonatomic) double maxValue;

/** 
 @discussion Must be greater or equal to 0 and less than @c maxValue. 
 */
@property (nonatomic) double minValue;

/** 
 @discussion Values that less than @c minValue or greater than @c endValue
             are ignored.
 */
@property (nonatomic) double startValue;

/** 
 @discussion Values that less than @c startValue and greater than @c maxValue
             are ignored.
 */
@property (nonatomic) double endValue;

/// Trim View drawing styles.
typedef NS_ENUM(NSUInteger, SLHTrimViewStyle) {
    
    /// Draw as a frame-like rectangle with open space in the center
    SLHTrimViewStyleFrame = 0,
    
    /// Draw as a solid rectangle
    SLHTrimViewStyleSimple
};

/**
 Access trimView drawing style.
 Default is @c SLHTrimViewStyleFrame.
 */
@property (nonatomic) SLHTrimViewStyle style;


/** Access the area of the trimView that is currently selected. */
 @property (nonatomic, readonly) NSRect selectionFrame;

/** Reset @c maxValue, @c minValue, @c startValue and @c endValue to defaults */
- (void)reset;

@end

@protocol SLHTrimViewDelegate <NSObject>

- (void)trimViewMouseDown:(SLHTrimView *)trimView;
- (void)trimViewMouseDownStartPosition:(SLHTrimView *)trimView;
- (void)trimViewMouseDownEndPosition:(SLHTrimView *)trimView;
- (void)trimViewMouseUp:(SLHTrimView *)trimView;

@end

NS_ASSUME_NONNULL_END
