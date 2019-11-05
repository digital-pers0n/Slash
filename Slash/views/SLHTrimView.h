//
//  SLHTrimView.h
//  Slash
//
//  Created by Terminator on 2019/11/05.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLHTrimView : NSView

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

@end

NS_ASSUME_NONNULL_END
