//
//  NSNotificationCenter+SLTAdditions.h
//  Slash
//
//  Created by Terminator on 2021/1/18.
//  Copyright © 2021年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/**
 This category provides functionality that is similar to
 @c -addObserverForName:object:queue:usingBlock: method, but without opaque 
 observer objects that you have to keep and remove manually later.
 */
__attribute((objc_direct_members))
@interface NSNotificationCenter (SLTAdditions)

/**
 Optionally, use one of -unregisterObserver:... methods to remove the observer
 later, NSNotificationCenter's removeObserver:... methods won't work.
 */
- (void)addObserver:(id)observer
               name:(nullable NSNotificationName)name
             object:(nullable id)object
            handler:(void(^)(id _Nullable object,
                             NSNotification *notification))block;

- (void)unregisterObserver:(id)observer
                      name:(nullable NSNotificationName)name
                    object:(nullable id)object;

- (void)unregisterObserver:(id)observer name:(nullable NSNotificationName)name;
- (void)unregisterObserver:(id)observer;

@end

NS_ASSUME_NONNULL_END
