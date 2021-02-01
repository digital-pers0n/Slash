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
                      handler:(void(^)(NSMenuItem *sender))block;

- (instancetype)initWithTitle:(NSString *)name
                      handler:(void(^)(NSMenuItem *sender))block;

@end

__attribute__((objc_direct_members))
@interface NSMenu (SLKAdditions)

- (NSMenuItem *)addItemWithTitle:(NSString *)string
                   keyEquivalent:(NSString *)charCode
                         handler:(void(^)(NSMenuItem *sender))block;

- (NSMenuItem *)addItemWithTitle:(NSString *)string
                         handler:(void(^)(NSMenuItem *sender))block;

@end

NS_ASSUME_NONNULL_END
