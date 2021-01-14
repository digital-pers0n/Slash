//
//  SLTUtils.m
//  Slash
//
//  Created by Terminator on 2020/9/12.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SLTUtils.h"

static NSString *_temporaryDirectoryPath = nil;

BOOL SLTTemporaryDirectoryInit(NSError **error) {
    if (!_temporaryDirectoryPath) {
        NSString *bundleId = NSBundle.mainBundle.bundleIdentifier;
        if (!bundleId) {
            bundleId = NSProcessInfo.processInfo.processName;
        }
        NSString *dir = NSTemporaryDirectory();
        dir = [dir stringByAppendingPathComponent:bundleId];
        NSFileManager *fm = NSFileManager.defaultManager;
        if (![fm fileExistsAtPath:dir isDirectory:nil]) {
            if (![fm createDirectoryAtPath:dir withIntermediateDirectories:YES
                                attributes:nil error:error]) {
                return NO;
            }
        }
        _temporaryDirectoryPath = dir;
    }
    return YES;
}

NSString *SLTTemporaryDirectory(void) {
    return _temporaryDirectoryPath;
}

BOOL SLTValidateFileName(NSString *fileName, NSError **outError) {
    NSError *error = nil;
    if (!fileName) {
        id info = @{
        NSLocalizedDescriptionKey : @"File name cannot be empty.",
        NSLocalizedRecoverySuggestionErrorKey : @"Provide a valid file name." };
        error = [NSError errorWithDomain:NSCocoaErrorDomain
                                    code:NSKeyValueValidationError
                                userInfo:info];
        goto bail;
    }
    
    const char *str = (fileName).UTF8String;
    if (!str) {
        id info = @{ NSFilePathErrorKey : fileName };
        error = [NSError errorWithDomain:NSCocoaErrorDomain
                                code:NSFileWriteInapplicableStringEncodingError
                            userInfo:info];
        goto bail;
    }
    
    if (strlen(str) > NAME_MAX) {
        id sug = [NSString stringWithFormat:
                  @"Must be less than %i bytes, current size is %zu bytes.",
                  NAME_MAX, strlen(str)];
        id info = @{ NSFilePathErrorKey : fileName,
                     NSLocalizedDescriptionKey : @"File name is too long.",
                     NSLocalizedRecoverySuggestionErrorKey : sug };
        
        error = [NSError errorWithDomain:NSCocoaErrorDomain
                                    code:NSFileWriteInvalidFileNameError
                                userInfo:info];
    }
    
bail:
    if (error) {
        if (outError) {
            *outError = error;
        }
        return NO;
    }
    return YES;
}

#if MAC_OS_X_VERSION_MIN_REQUIRED >= 110000
#define MAC_OS_1100_BUILD 1
#else
#define MAC_OS_1100_BUILD 0
#endif

BOOL SLTIsNoSelectionMarker(id value) {
#if MAC_OS_1100_BUILD
    return value == NSBindingSelectionMarker.noSelectionMarker;
#else
    return value == NSNoSelectionMarker;
#endif
}

BOOL SLTIsNotApplicableMarker(id value) {
#if MAC_OS_1100_BUILD
    return value == NSBindingSelectionMarker.notApplicableSelectionMarker;
#else
    return value == NSNotApplicableMarker;
#endif
}

NSString *const SLTPasteboardTypeFileURL() {
#if MAC_OS_1100_BUILD
    return NSPasteboardTypeFileURL;
#else 
    return (NSString *const)kUTTypeFileURL;
#endif
}

NSString *const SLTPasteboardTypeURL() {
#if MAC_OS_1100_BUILD
    return NSPasteboardTypeURL;
#else
    return (NSString *const)kUTTypeURL;
#endif
}
