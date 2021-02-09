//
//  SLTObserver.m
//  Slash
//
//  Created by Terminator on 2020/11/30.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLTObserver.h"
#import "SLTDefines.h"

#import <objc/runtime.h>

/*
 All of these UNSAFE aka __unsafe_unretained qualifiers are used because
 currently (checked with clang-12 -Ofast) under ARC lots of bogus retain /
 release calls are generated. As a result this causes longer compile times,
 breaks tail-call optimizations and generates larger binaries.
 */

@interface SLTNewValueObserver : SLTObserver
@end

@interface SLTToManyObserver : SLTObserver {
    NSArray<NSString *> *_keyPaths;
}
- (instancetype)initWithObject:(id)observable
                      keyPaths:(NSArray<NSString *> *)array
                       options:(NSKeyValueObservingOptions)mask
                       handler:(SLTObserverHandler)block;

@end

@interface SLTObserver () {
    @package
    void (^_handler)(id, id, id);
    __unsafe_unretained id _observable;
}
@end

@implementation SLTObserver

- (instancetype)initWithObject:(id)observable keyPath:(NSString *)kp
                       options:(NSKeyValueObservingOptions)mask
                       handler:(SLTObserverHandler)block {
    NSAssert(observable, @"Observable object cannot be nil");
    NSAssert(kp, @"Key path cannot be nil");
    NSAssert(block, @"Handler block cannot be nil");
    self = [super init];
    if (self) {
        _observable = observable;
        _keyPath = [kp copy];
        _handler = [block copy];
        [observable addObserver:self forKeyPath:kp options:mask
                        context:(__bridge void *)self];
    }
    return self;
}

- (instancetype)initWithObject:(UNSAFE id)observable
                       keyPath:(UNSAFE NSString *)kp
                       handler:(UNSAFE SLTObserverNewValueHandler)block
{
    return [[SLTNewValueObserver alloc]
            initWithObject:observable keyPath:kp
                   options:NSKeyValueObservingOptionNew handler:block];
}

- (instancetype)initWithObject:(UNSAFE id)observable
                      keyPaths:(UNSAFE NSArray<NSString *> *)kps
                       options:(NSKeyValueObservingOptions)mask
                       handler:(UNSAFE SLTObserverHandler)block
{
    return [[SLTToManyObserver alloc] initWithObject:observable keyPaths:kps
                                             options:mask handler:block];
}

- (void)observeValueForKeyPath:(UNSAFE NSString *)keyPath ofObject:(id)object
                        change:(UNSAFE NSDictionary *)change
                       context:(void *)context
{
    _handler(_observable, keyPath, change);
}

- (BOOL)isValid {
    return (_handler != nil);
}

- (void)invalidate {
    [_observable removeObserver:self
                     forKeyPath:_keyPath context:(__bridge void *)self];
    _handler = nil;
    _observable = nil;
}

- (void)dealloc {
    if (_handler) {
        [self invalidate];
    }
}

@end

@implementation SLTNewValueObserver

- (void)observeValueForKeyPath:(UNSAFE NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
    /* This trickery allows to tail-call handler() block,
       otherwise clang under ARC aggressively retain / release temporary
       objects and the last call will be always objc_release().
     */
    void *value = (__bridge void *)[change objectForKey:NSKeyValueChangeNewKey];
    _handler(_observable, keyPath, (__bridge id)value);
}

@end

@implementation SLTToManyObserver
- (instancetype)initWithObject:(id)observable
                      keyPaths:(NSArray<NSString *> *)keyPaths
                       options:(NSKeyValueObservingOptions)mask
                       handler:(SLTObserverHandler)block
{
    NSAssert(observable, @"Observable cannot be nil");
    NSAssert(keyPaths, @"Key paths array cannot be nil");
    NSAssert(block, @"Handler block cannot be nil");
    self = [super init];
    if (self) {
        _observable = observable;
        _handler = [block copy];
        _keyPaths = [[NSArray alloc] initWithArray:keyPaths copyItems:YES];
        for (NSString *keyPath in keyPaths) {
            [observable addObserver:self forKeyPath:keyPath
                            options:mask context:(__bridge void *)self];
        }
    }
    return self;
}

- (void)invalidate {
    id obj = _observable;
    for (NSString *keyPath in _keyPaths) {
        [obj removeObserver:self
                 forKeyPath:keyPath context:(__bridge void *)self];
    }
    _handler = nil;
    _observable = nil;
}

@end

@implementation NSObject (SLTKeyValueObservation)

- (SLTObserver *)observeKeyPath:(UNSAFE NSString *)kp
                        options:(NSKeyValueObservingOptions)mask
                        handler:(UNSAFE SLTObserverHandler)block
{
    return [[SLTObserver alloc] initWithObject:self
                                       keyPath:kp options:mask handler:block];
}

- (SLTObserver *)observeKeyPath:(UNSAFE NSString *)kp
                        handler:(UNSAFE SLTObserverNewValueHandler)block
{
    return [[SLTNewValueObserver alloc]
            initWithObject:self keyPath:kp
            options:NSKeyValueObservingOptionNew handler:block];
}

- (SLTObserver *)observeKeyPaths:(UNSAFE NSArray<NSString *> *)kps
                         options:(NSKeyValueObservingOptions)mask
                         handler:(UNSAFE SLTObserverHandler)block
{
    return [[SLTToManyObserver alloc] initWithObject:self keyPaths:kps
                                             options:mask handler:block];
}

static const void *
SLTObserverAssociationKey() {
    static const void *ctx = &ctx;
    return ctx;
}

static NSMutableDictionary<NSString *, NSMutableArray *> *
SLTObserverGetInfo(UNSAFE id obj, const void *key) {
    NSMutableDictionary *result = objc_getAssociatedObject(obj, key);
    if (!result) {
        result = [NSMutableDictionary dictionary];
        SLTObserverSetInfo(obj, result, key);
    }
    return result;
}

static void
SLTObserverSetInfo(UNSAFE id obj, UNSAFE NSDictionary *dict, const void *key) {
    objc_setAssociatedObject(obj, key, dict, OBJC_ASSOCIATION_RETAIN);
}

static NSMutableArray<SLTObserver *> *
SLTObserverGetArray(UNSAFE NSMutableDictionary *dict, UNSAFE NSString *key) {
    NSMutableArray *result = [dict objectForKey:key];
    if (!result) {
        result = [NSMutableArray array];
        [dict setObject:result forKey:key];
    }
    return result;
}

static __attribute((overloadable)) NSMutableArray<SLTObserver *> *
SLTObserverGetArray(UNSAFE id obj, UNSAFE NSString *key, const void *ctx) {
    NSMutableDictionary *info = SLTObserverGetInfo(obj, ctx);
    return SLTObserverGetArray(info, key);
}

static void
SLTObserverAdd(UNSAFE id object, UNSAFE SLTObserver *observer,
               UNSAFE NSString *key, const void *ctx) {
    NSCAssert(ctx, @"Context cannot be nil.");
    [SLTObserverGetArray(object, key, ctx) addObject:observer];
}


- (void)addObserver:(UNSAFE NSObject *)object
            keyPath:(UNSAFE NSString *)kp
            options:(NSKeyValueObservingOptions)mask
            context:(const void *)ctx
            handler:(UNSAFE SLTObserverHandler)block
{
    id observer = [self observeKeyPath:kp options:mask handler:block];
    SLTObserverAdd(object, observer, kp, ctx);
}

- (void)addObserver:(UNSAFE NSObject *)object
            keyPath:(UNSAFE NSString *)kp
            options:(NSKeyValueObservingOptions)mask
            handler:(UNSAFE SLTObserverHandler)block
{
    [self addObserver:object keyPath:kp options:mask
              context:SLTObserverAssociationKey() handler:block];
}

- (void)addObserver:(UNSAFE NSObject *)object
            keyPath:(UNSAFE NSString *)kp
            context:(const void *)ctx
            handler:(UNSAFE SLTObserverNewValueHandler)block
{
    id observer = [self observeKeyPath:kp handler:block];
    SLTObserverAdd(object, observer, kp, ctx);
}

- (void)addObserver:(UNSAFE NSObject *)object
            keyPath:(UNSAFE NSString *)kp
            handler:(UNSAFE SLTObserverNewValueHandler)block
{
    [self addObserver:object keyPath:kp
              context:SLTObserverAssociationKey() handler:block];
}

- (void)addObserver:(UNSAFE NSObject *)object
           keyPaths:(UNSAFE NSArray<NSString *>*)kps
            options:(NSKeyValueObservingOptions)mask
            context:(const void *)ctx
            handler:(UNSAFE SLTObserverHandler)block
{
    id observer = [self observeKeyPaths:kps options:mask handler:block];
    SLTObserverAdd(object, observer, SLTObserverMultipleValuesKeyPath, ctx);
}

- (void)addObserver:(UNSAFE NSObject *)object
           keyPaths:(UNSAFE NSArray<NSString *>*)kps
            options:(NSKeyValueObservingOptions)mask
            handler:(UNSAFE SLTObserverHandler)block
{
    [self addObserver:object keyPaths:kps options:mask
              context:SLTObserverAssociationKey() handler:block];
}

- (void)invalidateObserver:(UNSAFE NSObject *)object
                   keyPath:(UNSAFE NSString *)kp
                   context:(const void *)ctx
{
    NSAssert(ctx, @"Context cannot be nil.");
    NSMutableDictionary *info = SLTObserverGetInfo(object, ctx);
    if (!kp) {
        [info removeAllObjects];
        return;
    }
    
    NSMutableArray *array = SLTObserverGetArray(info, kp);
    NSAssert(array.count, @"%@ doesn't have any observed objects.",
             [object debugDescription]);
    
    NSArray *copy = array.copy;
    for (SLTObserver *obj in copy) {
        if (self == obj->_observable) {
            [array removeObject:obj];
        }
    }
    NSAssert(copy.count != array.count, @"%@ isn't observed by %@",
             [self debugDescription], [object debugDescription]);
}


- (void)invalidateObserver:(UNSAFE NSObject *)object
                   keyPath:(UNSAFE NSString *)kp {
    [self invalidateObserver:object
                     keyPath:kp context:SLTObserverAssociationKey()];
}
- (void)invalidateObserver:(UNSAFE NSObject *)object {
    [self invalidateObserver:object keyPath:nil];
}

NSString *const SLTObserverMultipleValuesKeyPath = @"multipleValuesKeyPath";

@end

