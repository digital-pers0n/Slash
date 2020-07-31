//
//  SLTFilterParameter.h
//  Slash
//
//  Created by Terminator on 2020/07/31.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLTFilterParameter : NSObject <NSCopying>

/** Filter parameter key. Can be nil if a filter takes only values. */
@property (nonatomic, nullable) NSString *key;

/** Filter parameter value. Must be NSString or NSNumber. */
@property (nonatomic) id value;

/** 
 If the @c key property is nil, return a stringified result of @c value property.
 Otherwise construct the result string as 'key=value'.
 */
@property (readonly) NSString *stringValue;

@end

NS_ASSUME_NONNULL_END
