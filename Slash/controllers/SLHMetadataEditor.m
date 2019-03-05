//
//  SLHMetadataEditor.m
//  Slash
//
//  Created by Terminator on 2019/03/04.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHMetadataEditor.h"

@interface SLHMetadataEditor () {
    
    IBOutlet NSTextView *_titleTextView;
    IBOutlet NSTextView *_artistTextView;
    IBOutlet NSTextView *_commentTextView;
    IBOutlet NSTextField *_dateTextField;
}

@end

@implementation SLHMetadataEditor

- (NSString *)windowNibName {
    return self.className;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

#pragma mark - IBActions

- (IBAction)okButtonAction:(id)sender {
}

- (IBAction)cancelButtonAction:(id)sender {
}

- (IBAction)applyButtonAction:(id)sender {
}

@end
