//
//  SLHFiltersController.h
//  Slash
//
//  Created by Terminator on 2018/11/22.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SLHEncoderItem;

@interface SLHFiltersController : NSViewController

+ (instancetype)filtersController;
@property SLHEncoderItem *encoderItem;

@end
