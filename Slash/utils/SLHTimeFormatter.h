//
//  SLHTimeFormatter.h
//  Slash
//
//  Created by Terminator on 2019/11/24.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLHTimeFormatter : NSNumberFormatter

+ (instancetype)sharedFormatter;

@property (nonatomic) double maxValue;
@property (nonatomic) double minValue;

@end

NS_ASSUME_NONNULL_END
