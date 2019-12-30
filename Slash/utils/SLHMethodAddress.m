//
//  SLHMethodAddress.m
//  Slash
//
//  Created by Terminator on 2019/12/29.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHMethodAddress.h"

@implementation SLHMethodAddress

- (instancetype)initWithTarget:(id)obj selector:(SEL)action {
    self = [super init];
    if (self) {
        _target = obj;
        _selector = action;
        _impl = [obj methodForSelector:action];
    }
    return self;
}

+ (instancetype)methodAddressWithTarget:(id)obj selector:(SEL)action {
    return [[SLHMethodAddress alloc] initWithTarget:obj selector:action];
}

@end
