//
//  SLTObserver.m
//  Slash
//
//  Created by Terminator on 2020/11/30.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLTObserver.h"

@interface SLTObserver () {
    void (^_observerHandler)(NSDictionary *);
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
}

- (void)dealloc {
    if (_observerHandler) {
        [self invalidate];
    }
}

@end
