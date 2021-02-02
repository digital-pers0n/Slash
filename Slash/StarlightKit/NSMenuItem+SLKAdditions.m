//
//  NSMenuItem+SLKAdditions.m
//  Slash
//
//  Created by Terminator on 2021/1/31.
//  Copyright © 2021年 digital-pers0n. All rights reserved.
//

#import "NSMenuItem+SLKAdditions.h"
#import "SLTDefines.h"
#import <objc/runtime.h>

@implementation NSMenuItem (SLKAdditions)

static const void *
SLKMenuItemAssociationKey() {
    static const void *ctx = &ctx;
    return ctx;
}

- (instancetype)initWithTitle:(UNSAFE NSString *)name
                keyEquivalent:(UNSAFE NSString *)code
                      handler:(UNSAFE void(^)(NSMenuItem *))block {
    
    self = [self initWithTitle:name action:@selector(callHandlerBlock:)
                 keyEquivalent:code];
    objc_setAssociatedObject(self, SLKMenuItemAssociationKey(), block,
                             OBJC_ASSOCIATION_COPY_NONATOMIC);
    self.target = self;
    return self;
}

- (instancetype)initWithTitle:(UNSAFE NSString *)name
                      handler:(UNSAFE void(^)(NSMenuItem *sender))block {
    return [self initWithTitle:name keyEquivalent:@"" handler:block];
}

- (void)callHandlerBlock:(UNSAFE id)sender {
    // to make it possible to tail-call the block
    void *block =
    (__bridge void*)objc_getAssociatedObject(self, SLKMenuItemAssociationKey());
    ((__bridge void(^)(id))block)(sender);
}

@end

@implementation NSMenu (SLKAdditions)

- (NSMenuItem *)addItemWithTitle:(UNSAFE NSString *)string
                   keyEquivalent:(UNSAFE NSString *)charCode
                         handler:(UNSAFE void(^)(NSMenuItem *sender))block {
    NSMenuItem *i = [[NSMenuItem alloc] initWithTitle:string
                                        keyEquivalent:charCode handler:block];
    [self addItem:i];
    return i;
}

- (NSMenuItem *)addItemWithTitle:(UNSAFE NSString *)string
                         handler:(UNSAFE void(^)(NSMenuItem *sender))block {
    return [self addItemWithTitle:string keyEquivalent:@"" handler:block];
}

@end
