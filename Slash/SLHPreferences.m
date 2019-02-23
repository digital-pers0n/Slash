//
//  SLHPreferences.m
//  Slash
//
//  Created by Terminator on 9/28/18.
//  Copyright © 2018 digital-pers0n. All rights reserved.
//

#import "SLHPreferences.h"

extern NSString *const SLHPreferencesDefaultOutputPath;

@interface SLHPreferences () {
    
    IBOutlet NSPopUpButton *_outputPathPopUp;
    
    NSMutableArray <NSString *> *_recentOutputPaths;
    NSString *_currentOutputPath;

}

@property IBOutlet NSTextField *ffmpegPathTextField;
@property IBOutlet NSTextField *ffprobePathTextField;
@property IBOutlet NSTextField *mpvPathTextField;

@end

@implementation SLHPreferences

- (NSString *)windowNibName {
    return self.className;
}

- (void)windowDidLoad {
    [super windowDidLoad];
}

- (IBAction)selectFile:(NSButton *)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSFileHandlingPanelOKButton) {
            NSString *value = panel.URLs.firstObject.path;
            [[NSUserDefaults standardUserDefaults] setValue:value forKey:sender.identifier];
            switch (sender.tag) {
                case 1:
                    _ffmpegPathTextField.stringValue = value;
                    break;
                case 2:
                    _ffprobePathTextField.stringValue = value;
                    break;
                case 3:
                    _mpvPathTextField.stringValue = value;
                    break;
                    
                default:
                    break;
            }
        }
    }];
    
}

@end
