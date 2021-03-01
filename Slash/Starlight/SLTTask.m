//
//  SLTTask.m
//  Slash
//
//  Created by Terminator on 2020/9/28.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//
#import "SLTTask.h"

#import "SLTDestination.h"
#import "SLTEncoderSettings.h"
#import "SLTFilter.h"
#import "SLTMediaSettings.h"
#import "SLTObserver.h"
#import "SLTSource.h"
#import "SLTUtils.h"

#import "MPVKitDefines.h"
#import "MPVPlayerItem.h"
#import "MPVPlayerItemTrack.h"

@interface SLTTask () {
}

@end

OBJC_DIRECT_MEMBERS
@implementation SLTTask

+ (instancetype)taskWithSource:(SLTSource *)src
                   destination:(SLTDestination *)dst {
    return [[self alloc] initWithSource:src destination:dst];
}

- (instancetype)initWithSource:(SLTSource *)src
                   destination:(SLTDestination *)dst {
    self = [super init];
    if (self) {
        _source = src;
        _destination = dst;
        _templateFormat = SLTCurrentTemplateFormat;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    typeof(self) obj = [[self.class allocWithZone:zone] init];
    obj->_source = _source;
    obj->_destination = _destination.copy;
    obj->_templateFormat = _templateFormat.copy;
    return obj;
}

#pragma mark - Arguments Array

- (NSArray<NSArray<NSString *> *> *)arguments {
    SLTEncoderSettings *settings = _destination.settings;
    NSMutableArray *result = [[NSMutableArray alloc] initWithArray:
        @[ SLTEncoderSettings.ffmpegPath,
           @"-nostdin", @"-hide_banner",
           @"-ss", @(_destination.startTime).stringValue,
           @"-i", _source.filePath,
           @"-t", @(_destination.duration).stringValue,
           @"-threads", @(SLTEncoderSettings.numberOfThreads).stringValue,
           @"-y" ]];
    [result addObjectsFromArray:self.filtersArguments];
    
    id args = settings.firstPassArguments;
    if (args) {
        [result addObjectsFromArray:
            @[@"-passlogfile", SLTTemporaryDirectory()]];
        
        NSMutableArray *firstPass = [result mutableCopy];
        [firstPass addObjectsFromArray:args];
        [firstPass addObjectsFromArray:@[ @"-f", @"null", @"/dev/null" ]];
        
        [result addObjectsFromArray:settings.arguments];
        [result addObjectsFromArray:self.metadataArguments];
        [result addObject:_destination.filePath];
        return @[firstPass, result];
    }
    
    [result addObjectsFromArray:settings.arguments];
    [result addObjectsFromArray:self.metadataArguments];
    [result addObject:_destination.filePath];
    
    return @[result];
}

- (NSArray *)filtersArguments {
    NSMutableArray *result = [NSMutableArray new];
    SLTEncoderSettings *settings = _destination.settings;
    
    void (^toString)() = ^(NSArray<SLTFilter *> *filters, NSString *type) {
        const NSInteger count = filters.count;
        if (!count) return;
        NSInteger idx = 0;
        NSMutableString *tmp = [NSMutableString new];
        for (SLTFilter *f in filters) {
            [tmp appendString:f.stringValue];
            if (++idx < count) {
                [tmp appendString:@","];
            }
        }
        [result addObjectsFromArray:@[ type, tmp ]];
    };
    
    if (settings.allowsVideoFilters) {
        toString(_destination.videoFilters, @"-vf");
    }
    
    if (settings.allowsAudioFilters) {
        toString(_destination.audioFilters, @"-af");
    }
    
    return result;
}

- (NSArray *)metadataArguments {
    NSMutableArray *result = [NSMutableArray new];
    [_destination.metadata enumerateKeysAndObjectsUsingBlock:
    ^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
         [result addObject:@"-metadata"];
         [result addObject:[NSString stringWithFormat:@"%@=%@", key, obj]];
    }];
    
    return result;
}

#pragma mark - Template Names

NSString *const SLTDefaultTemplateFormat = @"%f-%D";
static NSString *SLTCurrentTemplateFormat = SLTDefaultTemplateFormat;

+ (NSString *)currentTemplateFormat {
    return SLTCurrentTemplateFormat;
}

+ (void)setCurrentTemplateFormat:(NSString *)fmt {
    SLTCurrentTemplateFormat = fmt ? fmt.copy : SLTDefaultTemplateFormat;
}

+ (BOOL)validateTemplate:(NSString *)format error:(NSError **)error {
    const char * str = format.UTF8String;
    if (strlen(str) > NAME_MAX) {
        if (error) {
            *error = SLTTemplateIsTooLongError(strlen(str));
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
                *error = SLTTemplateInvalidSpecifierError(c);
            }
            return NO;
        }
    }
    return YES;
}

- (void)setTemplateFormat:(NSString *)format {
    if (!format) {
        _templateFormat = SLTCurrentTemplateFormat;
    } else {
        _templateFormat = format.copy;
    }
}

__attribute__((cold))
static NSError *SLTTemplateIsTooLongError(size_t len) {
    id desc = @"Template name is longer than the maximum allowed file name size.";
    id suggestion = [NSString stringWithFormat:@"Must be less than %i bytes. "
                     "Current size is %zu bytes.", NAME_MAX, len];
    return SLTErrorWithDomain(NSPOSIXErrorDomain,
                              ENAMETOOLONG, desc, suggestion);
}

__attribute__((cold))
static NSError *SLTTemplateInvalidSpecifierError(char s) {
    id desc = [NSString stringWithFormat:@"Invalid specifier %%%c\n", s];
    id suggestion =  @"Must be %f %d %D %r or %R";
    return SLTErrorWithDomain(NSCocoaErrorDomain,
                              NSFormattingError, desc, suggestion);
}

static NSError *SLTErrorWithDomain(NSErrorDomain domain, NSInteger code,
                                   NSString *description, NSString *suggestion)
{
    id info = @{ NSLocalizedDescriptionKey              : description,
                 NSLocalizedRecoverySuggestionErrorKey  : suggestion };
    return [NSError errorWithDomain:domain code:code userInfo:info];
}

static char *SLTStringFromSeconds(double value, char *buffer, size_t size) {
    
    int64_t time = (int64_t)value;
    const int64_t seconds = (time % 60);
    time = (time - seconds) / 60;
    const int64_t minutes = time % 60;
    const int64_t hours = (time - minutes) / 60;
    
    snprintf(buffer, size, "%02lli_%02lli_%06.3f", hours, minutes,
             (double)seconds + (seconds - floor(seconds)));
    return buffer;
}


static CFStringRef SLTCreateTruncatedName(char *string, size_t maxLen) {
    
    CFStringRef result = nil;
    char *end = string + maxLen;
    while (end > string) {
        *end-- = '\0';
        result = CFStringCreateWithCString(kCFAllocatorDefault,
                                           string, kCFStringEncodingUTF8);
        if (result) {
            break;
        }
    }
    return result;
}

static CFStringRef SLTCreateStringFromTemplate(NSString *format,
                                               SLTDestination *dest,
                                               SLTSource *source)
{
    const char *str = format.UTF8String;
    
    if (strlen(str) > NAME_MAX) {
        NSLog(@"%@ Falling back to the default template format.",
              SLTTemplateIsTooLongError(strlen(str)).description);
        str = SLTCurrentTemplateFormat.UTF8String;
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
                source.url.lastPathComponent.stringByDeletingPathExtension;
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
                SLTTimeInterval ti = dest.selectionRange;
                snprintf(buffer, sizeof(buffer), "%.3f-%.3f",
                         ti.start, ti.end);
                strlcat(result, buffer, sizeof(result));
                
                break;
            }
                
            case 'r':
            {
                char start[32];
                char end[32];
                SLTTimeInterval ti = dest.selectionRange;
                snprintf(buffer, sizeof(buffer), "%s-%s",
                         SLTStringFromSeconds(ti.start, start, sizeof(start)),
                         SLTStringFromSeconds(ti.end, end, sizeof(end)));
                strlcat(result, buffer, sizeof(result));
                
                break;
            }
                
            default:
                break;
        }
    }
    
    strlcat(result, str, sizeof(result));
    if (strlen(result) > NAME_MAX) {
        NSLog(@"Name is too long. Truncating...");
        return SLTCreateTruncatedName(result, NAME_MAX);
    }
    CFStringRef formatted = CFStringCreateWithCString(kCFAllocatorDefault,
                                                      result,
                                                      kCFStringEncodingUTF8);
    
    return formatted;
}

- (void)generateDestinationFileName {
    CFStringRef newName = SLTCreateStringFromTemplate(_templateFormat,
                                                      _destination, _source);
    NSError *fault = nil;
    if (!SLTValidateFileName((__bridge id)newName, &fault)) {
        NSLog(@"%s: %@", __PRETTY_FUNCTION__, fault);
        if (newName) CFRelease(newName);
        return;
    }
    _destination.fileName = CFBridgingRelease(newName);
}

@end
