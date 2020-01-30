//
//  SLHVideoSlider.h
//  Slash
//
//  Created by Terminator on 2020/01/27.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SLHVideoSliderDelegate;

@interface SLHVideoSlider : NSSlider

@property (nonatomic, weak, nullable) IBOutlet id <SLHVideoSliderDelegate> delegate;

@end

@protocol SLHVideoSliderDelegate <NSObject>

- (void)videoSlider:(SLHVideoSlider *)slider scrollWheelDeltaY:(double)deltaY;

@end

NS_ASSUME_NONNULL_END
