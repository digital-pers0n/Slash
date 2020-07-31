//
//  SLTFilterParameter.m
//  Slash
//
//  Created by Terminator on 2020/07/31.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLTFilterParameter.h"

@implementation SLTFilterParameter

- (id)copyWithZone:(NSZone *)zone {
    SLTFilterParameter *parameter = [[self.class allocWithZone:zone] init];
    parameter->_key = _key.copy;
    parameter->_value = [_value copy];
    return parameter;
}

- (NSString *)stringValue {
    NSString *string;
    if ([_value respondsToSelector:@selector(stringValue)]) {
        string = [_value stringValue];
    } else {
        string = _value;
    }
    if (_key) {
        return [NSString stringWithFormat:@"%@=%@", _key, string];
    }
    return string;
}

@end
