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

@interface SLTObserver () {
    @package
    void (^_observerHandler)(id);
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
        _observerHandler = [block copy];
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {

    _observerHandler(change);
}

- (BOOL)isValid {
    return (_observerHandler != nil);
}

- (void)invalidate {
    [_observable removeObserver:self
                     forKeyPath:_keyPath context:(__bridge void *)self];
    _observerHandler = nil;
    _observable = nil;
}

- (void)dealloc {
    if (_observerHandler) {
        [self invalidate];
    }
}

@end

@implementation SLTNewValueObserver

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
    /* This trickery allows to tail-call _observerHandler() block,
       otherwise clang under ARC aggressively retain / release temporary
       objects and the last call will be always objc_release().
     */
    void *value = (__bridge void *)[change objectForKey:NSKeyValueChangeNewKey];
    _observerHandler((__bridge id)value);
}

@end

