//
//  SLHVolumeButton.h
//  Slash
//
//  Created by Terminator on 2020/02/10.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLHVolumeButton : NSButton

@property (nonatomic) IBInspectable NSInteger maxValue;
@property (nonatomic) IBInspectable NSInteger minValue;

@end

NS_ASSUME_NONNULL_END
