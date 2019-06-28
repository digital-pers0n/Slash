//
//  SLHEncoderUniversalOptions.m
//  Slash
//
//  Created by Terminator on 2019/06/28.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHEncoderUniversalOptions.h"

@implementation SLHEncoderUniversalOptions

- (instancetype)init
{
    self = [super init];
    if (self) {
        _arguments = NSMutableArray.new;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    SLHEncoderUniversalOptions *obj = [super copyWithZone:zone];
    obj->_arguments = _arguments.mutableCopy;
    return obj;
}

@end
