//
//  SLHEncoderArgument.h
//  Slash
//
//  Created by Terminator on 2019/04/11.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLHEncoderArgument : NSObject

- (instancetype)initWithName:(NSString *)name value:(NSString *)value;

@property NSString *name;
@property NSString *value;

@end

NS_ASSUME_NONNULL_END