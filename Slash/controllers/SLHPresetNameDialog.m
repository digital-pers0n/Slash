//
//  SLHPresetNameDialog.m
//  Slash
//
//  Created by Terminator on 2019/06/18.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHPresetNameDialog.h"

@interface SLHPresetNameDialog ()

@end

@implementation SLHPresetNameDialog

- (NSString *)windowNibName {
    return self.className;
}


- (void)windowDidLoad {
    [super windowDidLoad];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (NSInteger)runModal {
    return [NSApp runModalForWindow:self.window];
}

- (IBAction)OKButtonClicked:(id)sender {
    [self.window endEditingFor:nil];
    if (_presetName.length) {
        [NSApp stopModalWithCode:NSModalResponseOK];
        [self.window orderOut:nil];
    } else {
        NSBeep();
    }
}

- (IBAction)cancelButtonClicked:(id)sender {
    [NSApp stopModalWithCode:NSModalResponseCancel];
    [self.window orderOut:nil];
}


@end
