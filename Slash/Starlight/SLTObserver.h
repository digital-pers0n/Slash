//
//  SLTObserver.h
//  Slash
//
//  Created by Terminator on 2020/11/30.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** Simple wrapper on top of KVO that can be used to observe changes in objects
 without overriding @c -observeValueForKeyPath:ofObject:change:context: method */
@interface SLTObserver : NSObject

- (instancetype)initWithObject:(id)observable
                       keyPath:(NSString *)kp
                       options:(NSKeyValueObservingOptions)mask
                       handler:(void (^)(NSDictionary *change))block;

/** Use @c NSKeyValueObservingOptionNew option to register the observer
 and pass the value associated with @c NSKeyValueChangeNewKey as the argument
 of the handler block. */
- (instancetype)initWithObject:(id)observable
                       keyPath:(NSString *)kp
                       handler:(void (^)(id newValue))block;

/** Observe changes in multiple key paths. */
- (instancetype)initWithObject:(id)observable
                      keyPaths:(NSArray<NSString *> *)kps
                       options:(NSKeyValueObservingOptions)mask
                       handler:(void (^)(NSString *keyPath, NSDictionary *change))block;

@property (readonly, nonatomic, nullable, assign) id observable;
@property (readonly, nonatomic) NSString *keyPath;

- (BOOL)isValid;
- (void)invalidate;

@end

#if __has_attribute(objc_direct)
__attribute((objc_direct_members))
#else
#warning Your compiler is too old and doesn't support direct methods. \
NSObject (SLTKeyValueObserving) category may silently override and break \
private methods in other classes.
#endif
@interface NSObject (SLTKeyValueObservation)

/* -observe:keyPath:... methods are somewhat similar to Swift's
 observe(_ keyPath:options:changeHandler:) -> NSKeyValueObservation
 */
- (SLTObserver *)observe:(NSObject *)object
                 keyPath:(NSString *)kp
                 options:(NSKeyValueObservingOptions)mask
                 handler:(void (^)(NSDictionary *change))block;

- (SLTObserver *)observe:(NSObject *)object
                 keyPath:(NSString *)kp
                 handler:(void (^)(id newValue))block;

- (SLTObserver *)observe:(NSObject *)object
                keyPaths:(NSArray<NSString *> *)kps
                 options:(NSKeyValueObservingOptions)mask
                 handler:(void (^)(NSString *keyPath, NSDictionary *change))block;

/* -addObserver:keyPath:... methods are all highly experimental. Use with care.
 
 These methods are similar to Cocoa's -addObserver:forKeyPath:options:context:
 but instead of calling -removeObserver:... one of -invalidateObserver:... 
 methods must be used before the observed object is released, otherwise 
 the program will crash.
 */

/** You must use the @c -invalidateObserver:keyPath:context: method to 
 invalidate the observer. */
- (void)addObserver:(NSObject *)object
            keyPath:(NSString *)kp
            options:(NSKeyValueObservingOptions)mask
            context:(const void *)ctx
            handler:(void (^)(NSDictionary *change))block;

- (void)addObserver:(NSObject *)object
            keyPath:(NSString *)kp
            options:(NSKeyValueObservingOptions)mask
            handler:(void (^)(NSDictionary *change))block;

/** You must use the @c -invalidateObserver:keyPath:context: method to 
 invalidate the observer. */
- (void)addObserver:(NSObject *)object
            keyPath:(NSString *)kp
            context:(const void *)ctx
            handler:(void (^)(id newValue))block;

- (void)addObserver:(NSObject *)object
            keyPath:(NSString *)kp
            handler:(void (^)(id newValue))block;

/** To invalidate this observer use @c SLTObserverMultipleValuesKeyPath
 the @c -invalidateObserver:keyPath:context: method must be used. */
- (void)addObserver:(NSObject *)object
           keyPaths:(NSArray<NSString *>*)kps
            options:(NSKeyValueObservingOptions)mask
            context:(const void *)ctx
            handler:(void (^)(NSString *keyPath, NSDictionary *change))block;

/** To invalidate this observer use @c SLTObserverMultipleValuesKeyPath */
- (void)addObserver:(NSObject *)object
           keyPaths:(NSArray<NSString *>*)kps
            options:(NSKeyValueObservingOptions)mask
            handler:(void (^)(NSString *keyPath, NSDictionary *change))block;

/** This method must be used to invalidate observers in case if a custom context
 was previously passed as an argument in one of -addObserver:keyPath:... methods.
 The other two -invalidateObserver:... methods only affect observers that 
 were associated with the default internal context.
 */
- (void)invalidateObserver:(NSObject *)object
                   keyPath:(nullable NSString *)kp
                   context:(const void *)ctx;

- (void)invalidateObserver:(NSObject *)object keyPath:(nullable NSString *)kp;
- (void)invalidateObserver:(NSObject *)object;

@end

extern NSString *const SLTObserverMultipleValuesKeyPath;

NS_ASSUME_NONNULL_END
