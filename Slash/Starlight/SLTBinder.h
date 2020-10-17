//
//  SLTBinder.h
//  Slash
//
//  Created by Terminator on 2020/10/17.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/** Class for handling simple one-to-one key-value bindings. */
@interface SLTBinder : NSObject {
    void (^_block)(void);
}

- (instancetype)initWithObject: (id)observable keyPath: (NSString *)kp
                       binding: (NSString *)name options: (NSDictionary *)dict
                       handler: (void (^)(void))block;

@property (nonatomic, readonly) id observable;
@property (nonatomic, readonly) NSString *keyPath;
@property (nonatomic, readonly) NSString *binding;
@property (nonatomic, readonly) NSDictionary *bindingOptions;
@property (nonatomic, readonly) NSDictionary *bindingInfo;
- (void)invalidate;
- (BOOL)isValid;

/** Access the keyPath value of the bound object. */
@property (nonatomic, nullable) id value;

@end

NS_ASSUME_NONNULL_END
