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

static void
SLKMenuItemSetHandler(UNSAFE NSMenuItem *obj, UNSAFE SLKMenuItemHandler block) {
    objc_setAssociatedObject(obj, SLKMenuItemAssociationKey(), block,
                             OBJC_ASSOCIATION_COPY_NONATOMIC);
}

SLKMenuItemHandler
SLKMenuItemGetHandler(UNSAFE NSMenuItem *obj) {
    return objc_getAssociatedObject(obj, SLKMenuItemAssociationKey());
}

static void
SLKMenuItemCallHandler(UNSAFE NSMenuItem *obj) {
    // to make it possible to tail-call the block
    void *block =
    (__bridge void*)objc_getAssociatedObject(obj, SLKMenuItemAssociationKey());
    ((__bridge SLKMenuItemHandler)block)(obj);
}

- (instancetype)initWithTitle:(UNSAFE NSString *)name
                keyEquivalent:(UNSAFE NSString *)code
                      handler:(UNSAFE void(^)(NSMenuItem *))block {
    
    self = [self initWithTitle:name action:@selector(callHandlerBlock:)
                 keyEquivalent:code];
    SLKMenuItemSetHandler(self, block);
    self.target = self;
    return self;
}

- (instancetype)initWithTitle:(UNSAFE NSString *)name
                      handler:(UNSAFE void(^)(NSMenuItem *sender))block {
    return [self initWithTitle:name keyEquivalent:@"" handler:block];
}

- (void)setHandlerBlock:(UNSAFE SLKMenuItemHandler)block {
    SLKMenuItemSetHandler(self, block ?: ^(NSMenuItem *i){});
}

- (SLKMenuItemHandler)handlerBlock {
    return SLKMenuItemGetHandler(self);
}

- (void)callHandlerBlock:(UNSAFE id)sender {
    SLKMenuItemCallHandler(self);
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
