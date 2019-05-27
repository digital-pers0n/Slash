//
//  SLHEncoderVPXFormat.m
//  Slash
//
//  Created by Terminator on 2019/05/27.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHEncoderVPXFormat.h"
#import "SLHEncoderItem.h"
#import "SLHFiltersController.h"

@interface SLHEncoderVPXFormat () {
    SLHFiltersController *_filters;
    SLHEncoderItem *_encoderItem;
    
    IBOutlet NSView *_videoView;
    IBOutlet NSView *_audioView;
}

@end

@implementation SLHEncoderVPXFormat

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

@end
