//
//  SLHTextEditor.h
//  Slash
//
//  Created by Terminator on 2019/07/02.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SLHTextEditor : NSViewController

@property (strong) IBOutlet NSTextView *textView;
@property (strong) IBOutlet NSButton *doneButton;
@property (strong) IBOutlet NSButton *cancelButton;

@end
