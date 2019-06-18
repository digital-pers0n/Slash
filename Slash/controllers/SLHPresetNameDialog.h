//
//  SLHPresetNameDialog.h
//  Slash
//
//  Created by Terminator on 2019/06/18.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SLHPresetNameDialog : NSWindowController

- (NSInteger)runModal;
@property NSString *presetName;


@end
