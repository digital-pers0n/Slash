//
//  SLTMediaSettings.m
//  Slash
//
//  Created by Terminator on 2020/08/02.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLTMediaSettings.h"

@implementation SLTMediaSettings

- (instancetype)init
{
    self = [super init];
    if (self) {
        _codecName = @"";
    }
    return self;
}

- (NSMutableArray<NSString *> *)arguments {
    return nil;
}

@end

@implementation SLTAudioSettings

@end

@implementation SLTVideoSettings

@end
