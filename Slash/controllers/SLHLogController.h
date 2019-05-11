//
//  SLHLogController.h
//  Slash
//
//  Created by Terminator on 2019/05/10.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLHLogController : NSWindowController

@property NSString *log;
- (void)runModal;

@end

NS_ASSUME_NONNULL_END