//
//  SLTFFmpegInfo.m
//  Slash
//
//  Created by Terminator on 2020/11/2.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLTFFmpegInfo.h"

#import "MPVKitDefines.h"

OBJC_DIRECT_MEMBERS
@implementation SLTFFmpegInfo

- (instancetype)initWithPath:(NSString *)path
                       error:(out NSError * _Nullable __autoreleasing *)error
{
    NSAssert(path, @"FFmpeg path cannot be nil.");
    
    self = [super init];
    if (!self) return nil;
    _path = path;
    if (![self collectInfoWithError:error]) return nil;
    
    return self;
}

- (BOOL)hasCodec:(NSString *)name {
    return [_supportedCodecs containsObject:name];
}

- (BOOL)hasFilter:(NSString *)name {
    return [_supportedFilters containsObject:name];
}

- (void)getError:(out NSError **)error
     withMessage:(NSString *)msg suggestion:(NSString *)sug
{
    if (!error) return;
    id dict = @{NSLocalizedDescriptionKey               : msg,
                NSLocalizedRecoverySuggestionErrorKey   : sug};
    *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                 code:NSExecutableLoadError
                             userInfo:dict];
}

- (BOOL)collectInfoWithError:(out NSError **)error {
    if (![self parseVersionWithError:error]) return NO;
    if (![self parseCodecsWithError:error]) return NO;
    if (![self parseFiltersWithError:error]) return NO;
    return YES;
}

- (BOOL)parseVersionWithError:(out NSError **)error {
    BOOL result = YES;
    NSMutableString *buildConfiguration;
    char *cmd;
    asprintf(&cmd, "%s -version", _path.UTF8String);
    FILE *ffmpeg = popen(cmd, "r");
    const int bufSize = 512;
    char buf[bufSize + 1];
    
    fgets(buf, bufSize, ffmpeg);
    char *str = strnstr(buf, "ffmpeg version ", bufSize);
    if (!str) {
        [self getError:error
           withMessage:@"Failed to find any version information."
            suggestion:@(buf)];
        result = NO;
        goto cleanup;
    }
    _versionString = @(str);

    buildConfiguration = [NSMutableString string];
    while (fgets(buf, bufSize, ffmpeg)) {
        [buildConfiguration appendString:@(buf)];
    }
    
    if (!buildConfiguration.length) {
        [self getError:error
           withMessage:@"Failed to find any build configuration information."
            suggestion:@(buf)];
        result = NO;
        goto cleanup;
    }
    
    _buildConfigurationString = buildConfiguration;
    
cleanup:
    
    free(cmd);
    pclose(ffmpeg);
    
    return result;
}

- (BOOL)parseCodecsWithError:(out NSError **)error {
    BOOL result = YES;
    NSMutableArray *codecs = [@[] mutableCopy];
    char *cmd;
    asprintf(&cmd, "%s -hide_banner -codecs", _path.UTF8String);
    FILE *ffmpeg = popen(cmd, "r");
    const int bufSize = 512;
    char buffer[bufSize + 1];
    
    while (fgets(buffer, bufSize, ffmpeg)) {
        if (strstr(buffer, "Codecs:")) {
            while (fgets(buffer, bufSize, ffmpeg)) {
                if (strstr(buffer, "=")) {
                    continue;
                } else {
                    while (fgets(buffer, bufSize, ffmpeg)) {
                        char *ptr = buffer;
                        while (*ptr) {
                            if (ptr[0] != 'D' && ptr[0] != '.') {
                                ptr++;
                                continue;
                            }
                            if (ptr[1] == 'E') {
                                NSArray *components =
                                [@(ptr) componentsSeparatedByString:@" "];
                                if (components.count > 1) {
                                    [codecs addObject:components[1]];
                                }
                            }
                            break;
                        }
                    }
                }
            }
        }
    }
    if (!codecs.count) {
        result = NO;
        [self getError:error withMessage:@"Failed to find any codecs."
            suggestion:@(buffer)];
    }
    
    _supportedCodecs = codecs;
    
    free(cmd);
    pclose(ffmpeg);
    
    return result;
}

- (BOOL)parseFiltersWithError:(out NSError **)error {
    BOOL result = YES;
    NSMutableArray *filters = [@[] mutableCopy];
    char *cmd;
    asprintf(&cmd, "%s -hide_banner -filters", _path.UTF8String);
    FILE *ffmpeg = popen(cmd, "r");
    const int bufSize = 512;
    char buffer[bufSize + 1];
    
    while (fgets(buffer, bufSize, ffmpeg))
    {
        if (strstr(buffer, "Filters:"))
        {
            while (fgets(buffer, bufSize, ffmpeg))
            {
                if (strstr(buffer, "=")) {
                    continue;
                } else {
                    while (fgets(buffer, bufSize, ffmpeg))
                    {
                        char *ptr = buffer;
                        while (*ptr) {
                            if (ptr[0] != 'T' && ptr[0] != '.') {
                                ptr++;
                                continue;
                            }
                            NSArray *components =
                            [@(ptr) componentsSeparatedByString:@" "];
                            if (components.count > 1) {
                                [filters addObject:components[1]];
                            }
                            break;
                        }
                    }
                }
            }
        }
    }
    
    if (!filters.count) {
        result = NO;
        [self getError:error withMessage:@"Failed to find any filters."
            suggestion:@(buffer)];
    }
    
    _supportedFilters = filters;
    
    free(cmd);
    pclose(ffmpeg);
    
    return result;
}

@end
