//
//  SLHBitrateFormatter.m
//  Slash
//
//  Created by Terminator on 2019/11/25.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHBitrateFormatter.h"

@implementation SLHBitrateFormatter

#define BIT    1.0
#define KBIT   1e3
#define MBIT   1e6
#define GBIT   1e9

- (NSString *)stringForObjectValue:(id)obj {
    
    double value = [obj doubleValue];
    double div;
    const char *suffix;
    
    if (value > GBIT) {
        div = GBIT;
        suffix = "Gbit/s";
    } else if (value > MBIT) {
        div = MBIT;
        suffix = "Mbit/s";
    } else if (value > KBIT) {
        div = KBIT;
        suffix = "kbit/s";
    } else {
        div = BIT;
        suffix = "bit/s";
    }
    
    NSString *result = [NSString stringWithFormat:@"%.2f %s", value / div, suffix];
    return result;
}

/* Even if a text field is not editable but selectable, it can still send this message to the formatter */
- (BOOL)getObjectValue:(out id  _Nullable __autoreleasing *)obj forString:(NSString *)string errorDescription:(out NSString *__autoreleasing  _Nullable *)error {
    return NO;
}

@end
