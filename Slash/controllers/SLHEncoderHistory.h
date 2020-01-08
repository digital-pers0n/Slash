//
//  SLHEncoderHistory.h
//  Slash
//
//  Created by Terminator on 2020/01/06.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLHEncoderHistory : NSWindowController

- (void)addItemWithPath:(NSString *)path log:(NSString *)log;

@end

NS_ASSUME_NONNULL_END
