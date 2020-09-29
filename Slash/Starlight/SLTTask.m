//
//  SLTTask.m
//  Slash
//
//  Created by Terminator on 2020/9/28.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLTTask.h"
#import "SLTSource.h"
#import "SLTDestination.h"

@implementation SLTTask

+ (instancetype)taskWithSource:(SLTSource *)src
                   destination:(SLTDestination *)dst {
    return [[self alloc] initWithSource:src destination:dst];
}

- (instancetype)initWithSource:(SLTSource *)src
                   destination:(SLTDestination *)dst {
    self = [super init];
    if (self) {
        _source = src;
        _destination = dst;
    }
    return self;
}

@end
