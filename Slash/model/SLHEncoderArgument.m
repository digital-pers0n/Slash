//
//  SLHEncoderArgument.m
//  Slash
//
//  Created by Terminator on 2019/04/11.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHEncoderArgument.h"

@implementation SLHEncoderArgument

- (instancetype)initWithName:(NSString *)name value:(NSString *)value {
    self = [super init];
    if (self) {
        _name = name;
        _value = value;
    }
    return self;
}

- (instancetype)init {
    return [self initWithName:@"" value:@""];
}

@end
