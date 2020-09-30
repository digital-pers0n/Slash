//
//  SLTTask.h
//  Slash
//
//  Created by Terminator on 2020/9/28.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SLTSource, SLTDestination;

@interface SLTTask : NSObject <NSCopying>

+ (instancetype)taskWithSource:(SLTSource *)src
                   destination:(SLTDestination *)dst;

- (instancetype)initWithSource:(SLTSource *)src
                   destination:(SLTDestination *)dst;

@property (nonatomic) SLTSource *source;
@property (nonatomic) SLTDestination *destination;

@end

NS_ASSUME_NONNULL_END
