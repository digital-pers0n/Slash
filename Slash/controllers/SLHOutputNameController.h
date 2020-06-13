//
//  SLHOutputNameController.h
//  Slash
//
//  Created by Terminator on 2020/04/14.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLHOutputNameController : NSViewController

@property (nonatomic, weak) IBOutlet NSArrayController *encoderItemsArrayController;

/** Indicate if the output file name is editable. */
@property (nonatomic) BOOL nameEditable;

@end

NS_ASSUME_NONNULL_END
