//
//  SLHModalWindowController.h
//  Slash
//
//  Created by Terminator on 2019/05/15.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLHModalWindowController : NSWindowController

@property NSView *contentView;
@property NSString *title;

- (void)runModal;

@end

NS_ASSUME_NONNULL_END