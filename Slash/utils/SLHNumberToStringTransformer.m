//
//  SLHNumberToStringTransformer.m
//  Slash
//
//  Created by Terminator on 2020/02/11.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLHNumberToStringTransformer.h"

@implementation SLHNumberToStringTransformer

+ (Class)transformedValueClass {
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)value {
    if (!value) {
        return value;
    }
    
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value stringValue];
    } else {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Value is not an instance of the NSNumber class. (Value is an instance of %@).",
         [value class]];
        return value;
    }
}

@end
