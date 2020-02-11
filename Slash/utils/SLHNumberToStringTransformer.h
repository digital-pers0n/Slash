//
//  SLHNumberToStringTransformer.h
//  Slash
//
//  Created by Terminator on 2020/02/11.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLHNumberToStringTransformer : NSValueTransformer

+ (Class)transformedValueClass;
+ (BOOL)allowsReverseTransformation;

/** Transform an instance of NSNumber to NSString */
- (nullable id)transformedValue:(nullable id)value;

@end

NS_ASSUME_NONNULL_END
