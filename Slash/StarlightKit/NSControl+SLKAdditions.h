//
//  NSControl+SLKAdditions.h
//  Slash
//
//  Created by Terminator on 2021/5/10.
//  Copyright © 2021年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^SLKControlActionHandler)(id sender);

__attribute__((objc_direct_members))
@interface NSControl (SLKAdditions)

@property (null_resettable, copy) SLKControlActionHandler actionHandler;

@end

NS_ASSUME_NONNULL_END
