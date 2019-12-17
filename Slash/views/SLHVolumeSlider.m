//
//  SLHVolumeSlider.m
//  Slash
//
//  Created by Terminator on 2019/12/17.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHVolumeSlider.h"

@implementation SLHVolumeSlider

- (void)scrollWheel:(NSEvent *)event {
    NSDictionary *info = [self infoForBinding:NSValueBinding];
    if (info) {
        CGFloat deltaY = -event.scrollingDeltaY;
        if (deltaY > 0 && deltaY < 1) {
            deltaY = 1;
        } else if (deltaY > -1 && deltaY < 0) {
            deltaY = -1;
        }
        
        CGFloat value = self.doubleValue + deltaY;
        if (value >= self.minValue && value <= self.maxValue) {
            [info[NSObservedObjectKey] setValue: @(value) forKeyPath: info[NSObservedKeyPathKey]];
        }
    }
}

@end
