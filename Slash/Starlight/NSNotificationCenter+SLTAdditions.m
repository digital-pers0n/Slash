//
//  NSNotificationCenter+SLTAdditions.m
//  Slash
//
//  Created by Terminator on 2021/1/18.
//  Copyright © 2021年 digital-pers0n. All rights reserved.
//

#import "NSNotificationCenter+SLTAdditions.h"
#import "SLTDefines.h"

#import <objc/runtime.h>

@interface SLTNotificationContext : NSObject {
    @package
    UNSAFE id _sender;
    NSString *_name;
    NSNotificationCenter *_notificationCenter;
    void(^_block)(id, NSNotification *);
}

@end

@implementation SLTNotificationContext

- (instancetype)initWithObject:(id)sender
                          name:(NSNotificationName)name
            notificationCenter:(NSNotificationCenter *)nc
                       handler:(void(^)(id, NSNotification *))block
{
    self = [super init];
    if (self) {
        _sender = sender;
        _notificationCenter = nc;
        _name = name.copy;
        _block = [block copy];
        [nc addObserver:self selector:@selector(notifyObserver:)
                   name:name object:sender];
    }
    return self;
}

- (void)notifyObserver:(UNSAFE NSNotification *)n {
    _block(_sender, n);
}

- (void)dealloc {
    [_notificationCenter removeObserver:self name:_name object:_sender];
}

@end

@implementation NSNotificationCenter (SLTAdditions)

static void const *
SLTNotificationAssociationKey() {
    static void const *ctx = &ctx;
    return ctx;
}

static NSMutableDictionary<NSString *, NSMutableArray *> *
SLTNotificationGetInfo(UNSAFE id obj) {
    NSMutableDictionary *result =
    objc_getAssociatedObject(obj, SLTNotificationAssociationKey());
    if (!result) {
        result = [NSMutableDictionary dictionary];
        SLTNotificationSetInfo(obj, result);
    }
    return result;
}

static void
SLTNotificationSetInfo(UNSAFE id obj, UNSAFE NSDictionary *dict) {
    objc_setAssociatedObject(obj, SLTNotificationAssociationKey(),
                             dict, OBJC_ASSOCIATION_RETAIN);
}

static NSMutableArray<SLTNotificationContext *> *
SLTNotificationGetArray(UNSAFE NSMutableDictionary *dict, UNSAFE NSString *key)
{
    NSMutableArray *result = [dict objectForKey:key];
    if (!result) {
        result = [NSMutableArray array];
        [dict setObject:result forKey:key];
    }
    return result;
}

static __attribute((overloadable)) NSMutableArray<SLTNotificationContext *> *
SLTNotificationGetArray(UNSAFE id obj, UNSAFE NSString *key) {
    NSMutableDictionary *info =
    SLTNotificationGetInfo(obj);
    return SLTNotificationGetArray(info, key);
}

static void
SLTNotificationAdd(UNSAFE id object,
                   UNSAFE SLTNotificationContext *observer,
                   UNSAFE NSString *key)
{
    [SLTNotificationGetArray(object, key) addObject:observer];
}


- (void)addObserver:(UNSAFE id)observer
               name:(nullable NSNotificationName UNSAFE)name
             object:(nullable id UNSAFE)object
            handler:(UNSAFE void(^)
                     (id, NSNotification *))block
{
    id ctx = [[SLTNotificationContext alloc] initWithObject:object name:name
                                         notificationCenter:self handler:block];
    SLTNotificationAdd(observer, ctx,
                       name ? name : @"SLTUnnamedNotificationKey");
}

- (void)unregisterObserver:(UNSAFE id)observer
                      name:(nullable NSNotificationName UNSAFE)name
                    object:(nullable id UNSAFE)object
{
    if (!name) {
        [SLTNotificationGetInfo(observer) removeAllObjects];
        return;
    }
    
    NSMutableArray *observers = SLTNotificationGetArray(observer, name);
    if (!object) {
        [observers removeAllObjects];
        return;
    }

    for (SLTNotificationContext *ctx in observers.copy) {
        if (ctx->_sender == object) {
            [observers removeObject:ctx];
        }
    }
}

- (void)unregisterObserver:(UNSAFE id)observer
                      name:(nullable NSNotificationName UNSAFE)name {
    [self unregisterObserver:observer name:name object:nil];
}

- (void)unregisterObserver:(UNSAFE id)observer {
    [self unregisterObserver:observer name:nil];
}

@end
