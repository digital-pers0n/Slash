//
//  SLHCropEditor.m
//  Slash
//
//  Created by Terminator on 2019/03/26.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHCropEditor.h"
#import "SLHImageView.h"
#import "SLHEncoderItem.h"
#import "SLHFilterOptions.h"

@interface SLHCropEditor () <SLHImageViewDelegate>

@end

@implementation SLHCropEditor

- (NSString *)windowNibName {
    return self.className;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

#pragma mark - SLHImageViewDelegate

- (void)imageView:(SLHImageView *)view didUpdateSelection:(NSRect)rect {
    SLHFilterOptions *options = _encoderItem.filters;
    options.videoCropX = rect.origin.x;
    options.videoCropY = rect.origin.y;
    options.videoCropWidth = rect.size.width;
    options.videoCropHeight = rect.size.height;
}

@end
