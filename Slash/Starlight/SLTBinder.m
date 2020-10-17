//
//  SLTBinder.m
//  Slash
//
//  Created by Terminator on 2020/10/17.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLTBinder.h"

@implementation SLTBinder

- (instancetype)initWithObject:(id)observable keyPath:(NSString *)kp
                       binding:(NSString *)name
                       options:(NSDictionary *)dict
                       handler:(void (^)(void))block {
    NSAssert(observable, @"Observable object cannot be nil");
    NSAssert(kp, @"Key path cannot be nil");
    NSAssert(name, @"Binding name cannot be nil");
    NSAssert(block, @"Block handler cannot be nil");
    self = [super init];
    if (self) {
        _observable = observable;
        _keyPath = [kp copyWithZone:nil];
        _binding = [name copyWithZone:nil];
        _bindingOptions = (dict) ? dict : @{};
        _block = [block copy];
        [observable addObserver:self
                     forKeyPath:kp options:0 context:(__bridge void *)_keyPath];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
    if (context == (__bridge void *)_keyPath) {
        _block();
        return;
    }
    // NSObject's implementation throws NSInternalInconsistencyException
#if DEBUG
    NSLog(@"%@ %s: Unknown context: %p must be: %p",
           self, __func__, context, (__bridge void *)_keyPath);
    NSLog(@"'%@' -> '%@' : [ %@ ]", object, keyPath, change);
    [super observeValueForKeyPath:keyPath ofObject:object
                           change:change context:context];
#endif
}

- (NSDictionary *)bindingInfo {
    return @{ NSObservedObjectKey:  _observable,
              NSObservedKeyPathKey: _keyPath,
              NSOptionsKey:         _bindingOptions };
}

- (void)invalidate {
    if (_block) {
        [_observable removeObserver:self
                         forKeyPath:_keyPath context:(__bridge void *)_keyPath];
        _block = nil;
    }
}

- (BOOL)isValid {
    return (BOOL)(_block != nil);
}

- (void)setValue:(id)object {
    [_observable setValue:object forKeyPath:_keyPath];
}

- (id)value {
    return [_observable valueForKeyPath:_keyPath];
}

- (void)dealloc {
    [self invalidate];
}

@end
