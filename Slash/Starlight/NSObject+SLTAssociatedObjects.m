//
//  NSObject+SLTAssociatedObjects.m
//  Slash
//
//  Created by Terminator on 2021/5/9.
//  Copyright © 2021年 digital-pers0n. All rights reserved.
//

#import "NSObject+SLTAssociatedObjects.h"
#import "SLTDefines.h"

#import <objc/runtime.h>

@implementation NSObject (SLTAssociatedObjects)

- (void)setWeakAOValue:(nullable UNSAFE id)val forKey:(const void *)key {
    objc_setAssociatedObject(self, key, val, OBJC_ASSOCIATION_ASSIGN);
}

- (void)setStrongAOValue:(nullable UNSAFE id)val forKey:(const void *)key {
    objc_setAssociatedObject(self, key, val, OBJC_ASSOCIATION_RETAIN);
}

- (void)setCopyAOValue:(nullable UNSAFE id)val forKey:(const void *)key {
    objc_setAssociatedObject(self, key, val, OBJC_ASSOCIATION_COPY);
}

- (void)setUnsafeStrongAOValue:(nullable UNSAFE id)val forKey:(const void *)key {
    objc_setAssociatedObject(self, key, val, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (void)setUnsafeCopyAOValue:(nullable UNSAFE id)val forKey:(const void *)key {
    objc_setAssociatedObject(self, key, val, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (nullable id)AOValueForKey:(const void *)key {
    return objc_getAssociatedObject(self, key);
}

@end
