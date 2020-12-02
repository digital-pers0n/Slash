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

@property (readonly, nonatomic, nullable, assign) id observable;
@property (readonly, nonatomic) NSString *keyPath;

- (BOOL)isValid;
- (void)invalidate;

@end

NS_ASSUME_NONNULL_END
