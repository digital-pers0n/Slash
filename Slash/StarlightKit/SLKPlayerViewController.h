//
//  SLKPlayerViewController.h
//  Slash
//
//  Created by Terminator on 2020/10/11.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLKPlayerViewController : NSViewController

+ (NSArray<NSString *> *)allowedPlayerViewNames;

- (BOOL)loadPlayerViewWithName:(NSString *)name error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
