//
//  NSDictionary+SLHPropertyListAddtions.m
//  Slash
//
//  Created by Terminator on 2020/06/28.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "NSDictionary+SLHPropertyListAddtions.h"

#if ENABLE_DICTIONARY_COMPAT

@implementation NSDictionary (SLHPropertyListAddtions)

- (BOOL)writeToURL:(NSURL *)url error:(out NSError **)error {
    NSData *tmp = [NSPropertyListSerialization
                   dataWithPropertyList:self format:NSPropertyListXMLFormat_v1_0
                   options:0 error:error];
    if (!tmp) {
        return NO;
    }
    return [tmp writeToURL:url options:NSDataWritingAtomic error:error];
}

+ (nullable NSDictionary<NSString *, id> *)
    dictionaryWithContentsOfURL:(NSURL *)url error:(out NSError **)error
{
    NSData *tmp = [NSData dataWithContentsOfURL:url
                                        options:NSDataReadingMappedIfSafe
                                          error:error];
    if (!tmp) {
        return nil;
    }
    return [NSPropertyListSerialization
            propertyListWithData:tmp options:NSPropertyListImmutable
            format:nil error:error];
}

@end

#endif // ENABLE_DICTIONARY_COMPAT
