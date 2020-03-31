//
//  SLHMethodObject.h
//  Slash
//
//  Created by Terminator on 2019/12/29.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLHMethodAddress : NSObject {
    @package
    SEL _selector;
    IMP _impl;
    __weak id _target;
}

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype)methodAddressWithTarget:(id)obj selector:(SEL)action;
- (instancetype)initWithTarget:(id)obj selector:(SEL)action;

@property (readonly, nonatomic) SEL selector;
@property (readonly, nonatomic) IMP impl;
@property (readonly, nonatomic, weak) id target;

@end

/** Function to make initializaiton shorter */
static inline SLHMethodAddress *addressOf(id target, SEL action) {
    return [SLHMethodAddress methodAddressWithTarget:target selector:action];
}

/** 
 Generic type for a setter method or any other method
 that has one parameter and return nothing.
 */
typedef void (*SLHSetterIMP)(id target, SEL selector, id parameter);

NS_ASSUME_NONNULL_END
