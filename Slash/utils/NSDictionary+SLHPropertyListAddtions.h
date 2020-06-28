//
//  NSDictionary+SLHPropertyListAddtions.h
//  Slash
//
//  Created by Terminator on 2020/06/28.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

#if !MAC_OS_X_VERSION_10_13 || \
MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_13
#define ENABLE_DICTIONARY_COMPAT 1
#else
#define ENABLE_DICTIONARY_COMPAT 0
#endif

#if ENABLE_DICTIONARY_COMPAT

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (SLHPropertyListAddtions)

- (BOOL)writeToURL:(NSURL *)url error:(out NSError **)error;
+ (nullable NSDictionary<NSString *, id> *)
    dictionaryWithContentsOfURL:(NSURL *)url error:(out NSError **)error;

@end

NS_ASSUME_NONNULL_END

#endif // ENABLE_DICTIONARY_COMPAT
