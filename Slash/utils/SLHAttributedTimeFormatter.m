//
//  SLHAttributedTimeFormatter.m
//  Slash
//
//  Created by Terminator on 2020/04/15.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLHAttributedTimeFormatter.h"
@import Cocoa;

@implementation SLHAttributedTimeFormatter

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self createAttributes];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self createAttributes];
    }
    return self;
}

- (void)createAttributes {
    
    // For some reason disabledControlTextColor doesn't work properly on MacOS 10.11
    _attrs = @{ NSForegroundColorAttributeName :
               // [[NSColor disabledControlTextColor] colorWithAlphaComponent:0.9] };
               // [NSColor disabledControlTextColor]
                [NSColor tertiaryLabelColor] };
}

static inline CFIndex indexOfFirstValidDigit(const char * cstr) {
    CFIndex idx = 0;
    while (cstr) {
        switch (*cstr) {
            case '0':
            case ':':
            case '.':
                ++idx;
                ++cstr;
                break;
                
            default:
                return idx;
        }
    }
    return idx;
}

static inline CFStringRef stringForDoubleValue(double value,
                                               CFIndex * len,
                                               CFIndex * indexOfValidDigit)
{
    int64_t time = (int64_t)value;
    int64_t seconds = (time % 60);
    time = (time - seconds) / 60;
    int64_t minutes = time % 60;
    int64_t hours = (time - minutes) / 60;
    char buffer[32];
    *len = snprintf(buffer, sizeof(buffer), "%02lli:%02lli:%06.3f", hours,
                    minutes, (double)seconds + (value - floor(value)));
    CFStringRef result = CFStringCreateWithCString(kCFAllocatorDefault, buffer,
                                                   kCFStringEncodingUTF8);
    *indexOfValidDigit = indexOfFirstValidDigit(buffer);
    return result;
}


static inline CFAttributedStringRef
attributedStringForDoubleValue(double value,
                               CFDictionaryRef mainAttrs,
                               CFDictionaryRef auxAttrs)
{
    CFIndex len = 0;
    CFIndex idx = 0;
    
    CFStringRef cfStr = stringForDoubleValue(value, &len, &idx);
    
    /* Use CFAttributedStringRef instead of NSAttributedString here, because
     NSAttributedString does not let you to apply new attributes without
     clearing the existing ones. */
    CFAttributedStringRef tmpStr = CFAttributedStringCreate(kCFAllocatorDefault,
                                                            cfStr,
                                                            mainAttrs);
    CFMutableAttributedStringRef aStr =
    CFAttributedStringCreateMutableCopy(kCFAllocatorDefault, len, tmpStr);
    CFAttributedStringSetAttributes(aStr, CFRangeMake(0, idx), auxAttrs, NO);
    CFRelease(cfStr);
    CFRelease(tmpStr);
    return aStr;
}
- (nullable NSAttributedString *)attributedStringForObjectValue:(id)obj
                                          withDefaultAttributes:(NSDictionary *)attrs
{
    CFDictionaryRef mainAttrs = (__bridge CFTypeRef)attrs;
    CFDictionaryRef auxAttrs = (__bridge CFTypeRef)_attrs;
    return CFBridgingRelease(attributedStringForDoubleValue([obj doubleValue],
                                                            mainAttrs,
                                                            auxAttrs));
}



@end
