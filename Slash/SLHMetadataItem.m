//
//  SLHMetadataItem.m
//  Slash
//
//  Created by Terminator on 2018/08/18.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import "SLHMetadataItem.h"

@implementation SLHMetadataItem

- (instancetype)init
{
    return [self initWithIdentifier:@"No identifer" value:@"No value"];
}

- (instancetype)initWithIdentifier:(NSString *)identifier value:(NSString *)value {
    self = [super init];
    if (self) {
        _identifier  = identifier;
        _value = value;
    }
    return self;
}

@end
