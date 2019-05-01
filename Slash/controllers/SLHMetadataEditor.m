//
//  SLHMetadataEditor.m
//  Slash
//
//  Created by Terminator on 2019/03/04.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHMetadataEditor.h"
#import "SLHEncoderItem.h"
#import "SLHEncoderItemMetadata.h"
#import "SLHMediaItem.h"
#import "SLHMetadataItem.h"
#import "SLHMetadataIdentifiers.h"

@interface SLHMetadataEditor () {
    
    IBOutlet NSTextView *_titleTextView;
    IBOutlet NSTextView *_artistTextView;
    IBOutlet NSTextView *_commentTextView;
    IBOutlet NSTextField *_dateTextField;
    SLHEncoderItem *_encoderItem;
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

- (void)_endEditing {
    
    SLHEncoderItemMetadata *metadata = [[SLHEncoderItemMetadata alloc] init];
    metadata.title = _titleTextView.string;
    metadata.artist = _artistTextView.string;
    metadata.comment = _commentTextView.string;
    metadata.date = _dateTextField.stringValue;
    _encoderItem.metadata = metadata.copy;
}

#pragma mark - Properties

- (void)setEncoderItem:(SLHEncoderItem *)encoderItem {
    _encoderItem = encoderItem;
    SLHEncoderItemMetadata *metadata = _encoderItem.metadata;

    _titleTextView.string = metadata.title;
   _artistTextView.string = metadata.artist;
    _commentTextView.string = metadata.comment;
    _dateTextField.stringValue = metadata.date;

}

- (SLHEncoderItem *)encoderItem {
    return _encoderItem;
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
