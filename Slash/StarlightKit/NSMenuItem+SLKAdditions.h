//
//  NSMenuItem+SLKAdditions.h
//  Slash
//
//  Created by Terminator on 2021/1/31.
//  Copyright © 2021年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface NSMenuItem (SLKAdditions)

- (instancetype)initWithTitle:(NSString *)name
                keyEquivalent:(NSString *)charCode
                      handler:(void(^)(id sender))block;

@end

NS_ASSUME_NONNULL_END
