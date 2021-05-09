//
//  NSObject+SLTAssociatedObjects.h
//  Slash
//
//  Created by Terminator on 2021/5/9.
//  Copyright © 2021年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface NSObject (SLTAssociatedObjects)

- (void)setWeakAOValue:(nullable id)value forKey:(const void *)key;
- (void)setStrongAOValue:(nullable id)value forKey:(const void *)key;
- (void)setCopyAOValue:(nullable id)value forKey:(const void *)key;

// thread unsafe
- (void)setUnsafeStrongAOValue:(nullable id)value forKey:(const void *)key;
- (void)setUnsafeCopyAOValue:(nullable id)value forKey:(const void *)key;

- (nullable id)AOValueForKey:(const void *)key;

@end

NS_ASSUME_NONNULL_END
