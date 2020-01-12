//
//  SLHTextEditor.m
//  Slash
//
//  Created by Terminator on 2019/07/02.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHTextEditor.h"

@interface SLHTextEditor () {
    IBOutlet NSTextView *_textView;
}

@end

@implementation SLHTextEditor

- (NSString *)nibName {
    return self.className;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _textView.smartInsertDeleteEnabled = NO;
    _textView.automaticDataDetectionEnabled = NO;
    _textView.automaticTextReplacementEnabled = NO;
    _textView.automaticQuoteSubstitutionEnabled = NO;
    _textView.automaticDashSubstitutionEnabled = NO;
    _textView.automaticSpellingCorrectionEnabled = NO;
}

@end
