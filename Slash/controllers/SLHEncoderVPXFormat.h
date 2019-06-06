//
//  SLHEncoderVPXFormat.h
//  Slash
//
//  Created by Terminator on 2019/05/27.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHEncoderBaseFormat.h"

@class SLHFiltersController;

@interface SLHEncoderVPXFormat : SLHEncoderBaseFormat

@property (readonly) NSView *videoView;
@property (readonly) NSView *audioView;
@property (readonly) SLHFiltersController *filters;

- (NSArray *)firstPassArguments;
- (NSArray *)videoArguments;
- (NSArray *)audioArguments;

@end
