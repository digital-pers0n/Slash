//
//  SLTUtils.m
//  Slash
//
//  Created by Terminator on 2020/9/12.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>
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
