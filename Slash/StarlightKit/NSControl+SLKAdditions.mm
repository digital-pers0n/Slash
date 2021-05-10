//
//  NSControl+SLKAdditions.m
//  Slash
//
//  Created by Terminator on 2021/5/10.
//  Copyright © 2021年 digital-pers0n. All rights reserved.
//

#import "NSControl+SLKAdditions.h"
#import "NSObject+SLTAssociatedObjects.h"
#import "SLTDefines.h"

@interface NSControl (SLKControlActionHandler) @end

[[clang::objc_direct_members]]
@implementation NSControl (SLKControlActionHandler)

namespace {
const void *SLKControlAOKey() {
    constexpr static const void *const key = &key;
    return key;
}
} // namespace

- (void)associateActionHandler:(UNSAFE SLKControlActionHandler)block {
    [self setUnsafeCopyAOValue:block forKey:SLKControlAOKey()];
}

- (SLKControlActionHandler)associatedActionHandler {
    return [self AOValueForKey:SLKControlAOKey()];
}

- (void)performActionHandler {
    // to make it possible to tail call the block
    auto block = (__bridge void*)[self associatedActionHandler];
    ((__bridge SLKControlActionHandler)block)(self);
}

@end

@implementation NSControl (SLKAdditions)

- (void)setActionHandler:(UNSAFE SLKControlActionHandler)block {
    if (!block) {
        [self associateActionHandler:^(NSControl*){}];
        return;
    }
    self.target = self;
    self.action = @selector(slk_performActionHandler:);
    [self associateActionHandler:block];
}

- (SLKControlActionHandler)actionHandler {
    return [self associatedActionHandler];
}

- (void)slk_performActionHandler:(UNSAFE id)sender {
    [self performActionHandler];
}

@end
