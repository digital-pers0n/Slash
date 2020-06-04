//
//  SLHTemplateNameFormatter.m
//  Slash
//
//  Created by Terminator on 2020/05/26.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLHTemplateNameFormatter.h"
#import "MPVPlayerItem.h"
#import "SLHEncoderItem.h"

@implementation SLHTemplateNameFormatter

static NSString * const kSLHDefaultTemplateNameFormat = @"%f-%D";

+ (NSString *)defaultTemplateFormat {
    return kSLHDefaultTemplateNameFormat;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _templateFormat = kSLHDefaultTemplateNameFormat;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _templateFormat = kSLHDefaultTemplateNameFormat;
    }
    return self;
}

- (void)setTemplateFormat:(NSString *)format {
    if (!format) {
        _templateFormat = kSLHDefaultTemplateNameFormat;
    } else {
        _templateFormat = format.copy;
    }
}

__attribute__((cold))
static NSString * nameIsTooLongError(size_t len) {
    return [NSString stringWithFormat:
            @"Template name is longer than the maximum allowed file "
            "name size. Must be less than %i bytes. Current size is %zu bytes.",
            NAME_MAX, len];
}

__attribute__((cold))
static NSString * invalidSpecifierError(char specifier) {
    return [NSString stringWithFormat: @"Invalid specifier %%%c\n"
            "Must be %%f %%d %%D %%r or %%R ", specifier];
}

static char * stringFromDouble(double value, char * buffer, size_t size) {
    
    int64_t time = (int64_t)value;
    const int64_t seconds = (time % 60);
    time = (time - seconds) / 60;
    const int64_t minutes = time % 60;
    const int64_t hours = (time - minutes) / 60;
    
    snprintf(buffer, size, "%02lli_%02lli_%06.3f", hours, minutes,
             (double)seconds + (value - floor(value)));
    return buffer;
}

static CFStringRef stringFromDocument(SLHEncoderItem * doc,
                                      NSString * template)
{
    const char * str = template.UTF8String;
    
    if (strlen(str) > NAME_MAX) {
        NSLog(@"%@ Falling back to the default template format.",
              nameIsTooLongError(strlen(str)));
        str = kSLHDefaultTemplateNameFormat.UTF8String;
    }
    
    char buffer[NAME_MAX + 1] = { 0 };
    char result[PATH_MAX + 1] = { 0 };
    
    while (1) {
        char *fmt = strchr(str, '%');
        if (!fmt) {
            break;
        }
        strncpy(buffer, str, fmt - str);
        buffer[fmt - str] = '\0';
        
        strlcat(result, buffer, sizeof(result));
        str = fmt + 1;
        char c = *str++;
        switch (c) {
            case 'f':
            {
                NSString *outputName =
                doc.playerItem.url.lastPathComponent.stringByDeletingPathExtension;
                strlcat(result, outputName.UTF8String, sizeof(result));
            }
                break;
                
            case 'd':
            {
                const time_t tSec = time(nil);
                const struct tm *stm = localtime(&tSec);
                snprintf(buffer, sizeof(buffer), "%i%02i%02i_%02i%02i%02i",
                         stm->tm_year + 1900, stm->tm_mon + 1, stm->tm_mday,
                         stm->tm_hour, stm->tm_min, stm->tm_sec);
                strlcat(result, buffer, sizeof(result));
                
                break;
            }
                
            case 'D':
            {
                const time_t tSec = time(nil);
                snprintf(buffer, sizeof(buffer), "%zu", tSec);
                strlcat(result, buffer, sizeof(result));
                
                break;
            }
                
            case 'R':
            {
                TimeInterval ti = doc.interval;
                snprintf(buffer, sizeof(buffer), "%.3f-%.3f",
                         ti.start, ti.end);
                strlcat(result, buffer, sizeof(result));
            
                break;
            }
                
            case 'r':
            {
                char start[32];
                char end[32];
                TimeInterval ti = doc.interval;
                snprintf(buffer, sizeof(buffer), "%s-%s",
                         stringFromDouble(ti.start, start, sizeof(start)),
                         stringFromDouble(ti.end, end, sizeof(end)));
                strlcat(result, buffer, sizeof(result));
                
                break;
            }
                
            default:
                break;
        }
    }
    
    strlcat(result, str, sizeof(result));
    if (strlen(result) > NAME_MAX) {
        NSLog(@"Template name is too long.");
    }
    CFStringRef formatted = CFStringCreateWithCString(kCFAllocatorDefault,
                                                      result,
                                                      kCFStringEncodingUTF8);
    
    return formatted;
}

- (NSString *)stringForObjectValue:(id)obj {
    if (!obj || [obj isKindOfClass:[NSString class]]) {
        // Template edit mode.
        return obj;
    }
    NSAssert([obj isKindOfClass:[SLHEncoderItem class]],
             @"'%@' is an invalid object value class. Must be 'SLHEncoderItem'",
             [obj class]);
    SLHEncoderItem * doc = obj;
    
    return CFBridgingRelease(stringFromDocument(doc, _templateFormat));
}

- (NSString *)stringFromDocument:(SLHEncoderItem *)document {
    return CFBridgingRelease(stringFromDocument(document, _templateFormat));
}

- (BOOL)getObjectValue:(out id _Nullable * _Nullable)obj
             forString:(NSString *)string
      errorDescription:(out NSString * _Nullable * _Nullable)error
{
    const char * str = string.UTF8String;
    if (strlen(str) > NAME_MAX) {
        if (error) {
            *error = nameIsTooLongError(strlen(str));
        }
        return NO;
    }
    while (1) {
        char *fmt = strchr(str, '%');
        if (!fmt) {
            break;
        }
        str = fmt + 1;
        char c = *str++;
        if (c != 'd' && c != 'f' && c != 'r' && c != 'D' && c != 'R' ) {
            if (error) {
                *error = invalidSpecifierError(c);
            }
            return NO;
        }
    }
    if (obj) {
        *obj = string;
    }
    return YES;
}

@end
