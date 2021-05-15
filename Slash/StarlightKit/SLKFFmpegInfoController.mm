//
//  SLKFFmpegInfoController.mm
//  Slash
//
//  Created by Terminator on 2021/4/30.
//  Copyright © 2021年 digital-pers0n. All rights reserved.
//

#import "SLKFFmpegInfoController.h"
#import "NSControl+SLKAdditions.h"

#import "SLTFFmpegInfo.h"

#import "Dispatch.h"

@interface SLKFFmpegInfoController ()
@property (nonatomic, assign) IBOutlet NSPopUpButton *encodersPopUp, *filtersPopUp;
@property (nonatomic, assign) IBOutlet NSTextView *helpTextView;
@property (nonatomic, assign) IBOutlet NSSearchField *searchField;
@property (nonatomic, nullable) SLTFFmpegInfo *info;

@end

[[clang::objc_direct_members]]
@implementation SLKFFmpegInfoController

- (NSNibName)windowNibName {
    return self.className;
}

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken{};
    static SLKFFmpegInfoController *result{};
    
    dispatch_once(&onceToken, ^{
        result = [[SLKFFmpegInfoController alloc] init];
    });
    
    return result;
}

- (void)updateInfoWithPath:(NSString *)path {
    if (!path) {
        if (_info) {
            self.info = nil;
            self.window.title = @"Not Available";
            _helpTextView.string = @" ";
        }
        return;
    }
    __unsafe_unretained auto u = self;
    
    Dispatch::GlobalQueue().async(^{
        auto info = [[SLTFFmpegInfo alloc] initWithPath:path handler:
        ^(NSError * _Nonnull e) {
            Dispatch::MainQueue().async(^{
                if (u.isWindowLoaded) {
                    u->_helpTextView.string = e.localizedDescription;
                    u.window.title = @"Error";
                }
                NSLog(@"%@", e);
                u.info = nil;
            }); //MainQueue
        }]; // SLTFFmpegInfo
        
        if (!info) return;
        
        Dispatch::MainQueue().async(^{
            u.info = info;
            if (!u.isWindowLoaded) return;
            [u updateUI];
        });
    }); // GloablQueue
}

- (void)windowDidLoad {
    [super windowDidLoad];
    if (_info) {
        [self updateUI];
    }
    [self setUpPopUps];
}

- (void)setUpPopUps {
    __unsafe_unretained auto u = self;
    
    _filtersPopUp.actionHandler = ^(NSPopUpButton *sender) {
        u->_helpTextView.string =
        [u->_info helpForFilter:sender.titleOfSelectedItem];
    };
    
    _encodersPopUp.actionHandler = ^(NSPopUpButton *sender) {
        u->_helpTextView.string =
        [u->_info helpForEncoder:sender.titleOfSelectedItem];
    };
}

- (void)updateUI {
    [self.window setTitleWithRepresentedFilename:_info.path];
    [_encodersPopUp removeAllItems];
    [_filtersPopUp removeAllItems];
    [_encodersPopUp addItemsWithTitles:_info.encoders];
    [_filtersPopUp addItemsWithTitles:_info.filters];
    _helpTextView.string = @" ";
}

@end
