//
//  MPVMetadataItem.m
//  Slash
//
//  Created by Terminator on 2019/10/21.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "MPVMetadataItem.h"

@implementation MPVMetadataItem

- (instancetype)init {
    return [self initWithIdentifier:@"Empty" value:@"Empty"];
}

- (instancetype)initWithIdentifier:(NSString *)identifier value:(NSString *)value {
    self = [super init];
    if (self) {
        _identifier = identifier.copy;
        _value = value.copy;
    }
    return self;
}

@end
