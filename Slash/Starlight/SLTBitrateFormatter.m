//
//  SLTBitrateFormatter.m
//  Slash
//
//  Created by Terminator on 2020/9/8.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLTBitrateFormatter.h"

@implementation SLTBitrateFormatter


#define BIT    1.0
#define KBIT   1e3
#define MBIT   1e6
#define GBIT   1e9

static inline CFStringRef SLTBitrateToString(double value) {
    double div;
    const char *suffix;
    
    if (value > GBIT) {
        div = GBIT;
        suffix = "Gbps";
    } else if (value > MBIT) {
        div = MBIT;
        suffix = "Mbps";
    } else if (value > KBIT) {
        div = KBIT;
        suffix = "kbps";
    } else {
        div = BIT;
        suffix = "bps";
    }
    char buffer[32];
    snprintf(buffer, sizeof(buffer), "%.2f %s", value / div, suffix);
    CFStringRef result = CFStringCreateWithCString(kCFAllocatorDefault, buffer,
                                                   kCFStringEncodingUTF8);
    return result;
}

NS_FORMAT_FUNCTION(2,3)
static void SLTSetErrorString(NSString **error, NSString *fmt, ...) {
    if (error) {
        va_list ap;
        va_start(ap, fmt);
        *error = [[NSString alloc] initWithFormat:fmt locale:nil arguments:ap];
        va_end(ap);
    }
}

NSString *SLTBitrateFormatterStringForDoubleValue(double value) {
    return CFBridgingRelease(SLTBitrateToString(value));
}

#pragma mark - Overrides

- (NSString *)stringForObjectValue:(id)obj {
    double value = [obj doubleValue];
    return CFBridgingRelease(SLTBitrateToString(value));
}

- (BOOL)getObjectValue:(out id  _Nullable __autoreleasing *)obj
             forString:(NSString *)string
      errorDescription:(out NSString *__autoreleasing  _Nullable *)error
{
    if (!obj) {
        return NO;
    }
    
    const char *buffer = string.UTF8String;
    char *bufferEnd = nil;
    double value = strtod(buffer, &bufferEnd);
    if (bufferEnd == buffer) {
        SLTSetErrorString(error, @"Malformed Input.");
        return NO;
    }
    
    double mult = BIT;
    BOOL stop = NO;
    while (!stop && *bufferEnd) {
        if (!isspace(*bufferEnd)) {
            switch (*bufferEnd) {
                case 'M': case 'm':
                    stop = YES;
                    mult = MBIT;
                    break;
                    
                case 'K': case 'k':
                    stop = YES;
                    mult = KBIT;
                    break;
                    
                case 'G':  case 'g':
                    stop = YES;
                    mult = GBIT;
                    break;
                    
                default:
                    break;
            }
        }
        ++bufferEnd;
    }
    value *= mult;
    
    if (value < self.minimum.doubleValue) {
        SLTSetErrorString(error, @"%.0f is too small.", value);
        return NO;
    }
    
    if (value > self.maximum.doubleValue) {
        SLTSetErrorString(error, @"%.0f is too large.", value);
        return NO;
    }
    
    *obj = @(value);
    
    return YES;
}

@end
