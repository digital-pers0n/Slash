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
                      handler:(UNSAFE void(^)(id sender))block {
    
    self = [self initWithTitle:name action:@selector(callHandlerBlock:)
                 keyEquivalent:code];
    objc_setAssociatedObject(self, SLKMenuItemAssociationKey(), block,
                             OBJC_ASSOCIATION_COPY_NONATOMIC);
    self.target = self;
    return self;
}

- (void)callHandlerBlock:(UNSAFE id)sender {
    // to make it possible to tail-call the block
    void *block =
    (__bridge void*)objc_getAssociatedObject(self, SLKMenuItemAssociationKey());
    ((__bridge void(^)(id))block)(sender);
}

@end
