//
//  SLTObserver.m
//  Slash
//
//  Created by Terminator on 2020/11/30.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLTObserver.h"

@interface SLTNewValueObserver : SLTObserver
@end

@interface SLTToManyObserver : SLTObserver {
    NSArray<NSString *> *_keyPaths;
}
- (instancetype)initWithObject:(id)observable
                      keyPaths:(NSArray<NSString *> *)array
                       options:(NSKeyValueObservingOptions)mask
                       handler:(void (^)(NSString *, NSDictionary *))block;

@end

@interface SLTObserver () {
    @package
    union {
        void (^base)(id);
        void (^toMany)(id, id);
    } _handler;
    __unsafe_unretained id _observable;
}
@end

@implementation SLTObserver

- (instancetype)initWithObject:(id)observable keyPath:(NSString *)kp
                       options:(NSKeyValueObservingOptions)mask
                       handler:(void (^)(NSDictionary *changeDict))block {
    NSAssert(observable, @"Observable object cannot be nil");
    NSAssert(kp, @"Key path cannot be nil");
    NSAssert(block, @"Handler block cannot be nil");
    self = [super init];
    if (self) {
        _observable = observable;
        _keyPath = [kp copy];
        _handler.base = [block copy];
        [observable addObserver:self forKeyPath:kp options:mask
                        context:(__bridge void *)self];
    }
    return self;
}

- (instancetype)initWithObject:(id)observable keyPath:(NSString *)kp
                       handler:(void (^)(id _Nonnull))block {
    return [[SLTNewValueObserver alloc]
            initWithObject:observable keyPath:kp
                   options:NSKeyValueObservingOptionNew handler:block];
}

- (instancetype)initWithObject:(id)observable
                      keyPaths:(NSArray<NSString *> *)kps
                       options:(NSKeyValueObservingOptions)mask
                       handler:(void (^)(NSString *, NSDictionary *))block
{
    return [[SLTToManyObserver alloc] initWithObject:observable keyPaths:kps
                                             options:mask handler:block];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    _handler.base(change);
}

- (BOOL)isValid {
    return (_handler.base != nil);
}

- (void)invalidate {
    [_observable removeObserver:self
                     forKeyPath:_keyPath context:(__bridge void *)self];
    _handler.base = nil;
    _observable = nil;
}

- (void)dealloc {
    if (_handler.base) {
        [self invalidate];
    }
}

@end

@implementation SLTNewValueObserver

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
    /* This trickery allows to tail-call handler() block,
       otherwise clang under ARC aggressively retain / release temporary
       objects and the last call will be always objc_release().
     */
    void *value = (__bridge void *)[change objectForKey:NSKeyValueChangeNewKey];
    _handler.base((__bridge id)value);
}

@end

@implementation SLTToManyObserver
- (instancetype)initWithObject:(id)observable
                      keyPaths:(NSArray<NSString *> *)keyPaths
                       options:(NSKeyValueObservingOptions)mask
                       handler:(void (^)(NSString *, NSDictionary *))block
{
    NSAssert(observable, @"Observable cannot be nil");
    NSAssert(keyPaths, @"Key paths array cannot be nil");
    NSAssert(block, @"Handler block cannot be nil");
    self = [super init];
    if (self) {
        _observable = observable;
        _handler.toMany = [block copy];
        _keyPaths = [[NSArray alloc] initWithArray:keyPaths copyItems:YES];
        for (NSString *keyPath in keyPaths) {
            [observable addObserver:self forKeyPath:keyPath
                            options:mask context:(__bridge void *)self];
        }
    }
    return self;
}

- (void)observeValueForKeyPath:(__unsafe_unretained NSString *)keyPath
                      ofObject:(id)object change:(NSDictionary *)change
                       context:(void *)context
{
    _handler.toMany(keyPath, change);
}

- (void)invalidate {
    id obj = _observable;
    for (NSString *keyPath in _keyPaths) {
        [obj removeObserver:self
                 forKeyPath:keyPath context:(__bridge void *)self];
    }
    _handler.toMany = nil;
    _observable = nil;
}

@end

