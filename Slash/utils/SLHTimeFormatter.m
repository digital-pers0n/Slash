//
//  SLHTimeFormatter.m
//  Slash
//
//  Created by Terminator on 2019/11/24.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHTimeFormatter.h"

@implementation SLHTimeFormatter

+ (instancetype)sharedFormatter {
    static id obj = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        obj = [[self.class alloc] init];
    });
    
    return obj;
}

static inline CFStringRef _stringForDoubleValue(double value) {
    
    int64_t time = (int64_t)value;
    int64_t seconds = (time % 60);
    time = (time - seconds) / 60;
    int64_t minutes = time % 60;
    int64_t hours = (time - minutes) / 60;
    char buffer[32];
    snprintf(buffer, sizeof(buffer), "%02lli:%02lli:%06.3f", hours, minutes, (double)seconds + (value - floor(value)));
    CFStringRef result = CFStringCreateWithCString(kCFAllocatorDefault, buffer, kCFStringEncodingUTF8);
    return result;
}

NSString *SLHTimeFormatterStringForDoubleValue(double value) {
    return CFBridgingRelease(_stringForDoubleValue(value));
}

- (NSString *)stringForObjectValue:(id)obj {
    double value = [obj doubleValue];
    return CFBridgingRelease(_stringForDoubleValue(value));
}

- (BOOL)getObjectValue:(out id  _Nullable __autoreleasing *)obj
             forString:(NSString *)string
      errorDescription:(out NSString *__autoreleasing  _Nullable *)error {
    
    if (obj) {
        
        NSArray <NSString *> *components = [string componentsSeparatedByString:@":"];
        NSUInteger count = components.count;
        
        if (count > 0) {
            if (count == 3) {
                double hours = components[0].doubleValue * 3600;
                double minutes = components[1].doubleValue * 60;
                double seconds = components[2].doubleValue;
                double total = hours + minutes + seconds;
                if (![super getObjectValue:obj forString:@(total).stringValue errorDescription:error]) {
                    return NO;
                }
                *obj = @(total);
                return YES;
            }
            
            if (count == 1) { // try to convert the whole string
                double time = components[0].doubleValue;
                
                if (time > self.maximum.doubleValue) {
                    if (error) {
                        *error = [NSString stringWithFormat:@"%g is too large", time];
                    }
                    return NO;
                }
                
                *obj = @(time);
                return YES;
            }
        }
        
        if (error) {
            *error = @"Malformed Input";
        }
    }
    
    return NO;
}


- (BOOL)isPartialStringValid:(NSString *)partialString
            newEditingString:(NSString *__autoreleasing  _Nullable *)newString
            errorDescription:(NSString *__autoreleasing  _Nullable *)error {
    
    const char *inputString = (partialString.UTF8String);
    
    if (inputString) {
        const char *iterator = inputString;
        BOOL malformed = NO;
        int separators = 0;
        int dot = 0;
        while (*iterator) {
            
            if (!isdigit(*iterator)) {
                if (*iterator == ':') {
                    if (separators > 1) {
                        goto error;
                    } else {
                        iterator++;
                        separators++;
                        continue;
                    }
                }
                
                if (*iterator == '.') {
                    if (dot > 0) {
                        goto error;
                    } else {
                        iterator++;
                        dot++;
                        continue;
                    }
                }
                
            error:
                malformed = YES;
                break;
            }
            iterator++;
        }
        
        if (malformed) {
            if (error) {
                *error = @"Malformed Input";
            }
            return NO;
        }
        return YES;
    }
    
    return NO;
}

@end
