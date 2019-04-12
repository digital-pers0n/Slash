//
//  SLHMetadataEditor.m
//  Slash
//
//  Created by Terminator on 2019/03/04.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHMetadataEditor.h"
#import "SLHEncoderItem.h"
#import "SLHMediaItem.h"
#import "SLHMetadataItem.h"
#import "SLHMetadataIdentifiers.h"

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

static inline NSString * _getValue(NSDictionary *dict, NSString *key) {
    NSString *str = dict[key];
    return (str) ? str : @"";
}

- (void)reloadData {
    NSDictionary *data = [_delegate dataForMetadataEditor:self];
    _artistTextView.string = _getValue(data, SLHMetadataIdentifierArtist);
    _titleTextView.string = _getValue(data, SLHMetadataIdentifierTitle);
    _dateTextField.stringValue = _getValue(data, SLHMetadataIdentifierDate);
    _commentTextView.string = _getValue(data, SLHMetadataIdentifierComment);
    
}

- (void)_endEditing {
    NSDictionary *data = @{ SLHMetadataIdentifierArtist: _artistTextView.string.copy,
                            SLHMetadataIdentifierTitle: _titleTextView.string.copy,
                            SLHMetadataIdentifierDate: _dateTextField.stringValue.copy,
                            SLHMetadataIdentifierComment: _commentTextView.string.copy};
    [_delegate metadataEditor:self didEndEditing:data];
}

#pragma mark - IBActions

- (IBAction)okButtonAction:(id)sender {
    [self _endEditing];
    [self.window close];
}

- (IBAction)cancelButtonAction:(id)sender {
    [self.window close];
}

- (IBAction)applyButtonAction:(id)sender {
    [self _endEditing];
}

#pragma mark - NSWindowDelegate

- (void)windowDidBecomeMain:(NSNotification *)notification {
    _hasWindow = YES;
}

- (void)windowWillClose:(NSNotification *)notification {
    _hasWindow = NO;
}

@end
