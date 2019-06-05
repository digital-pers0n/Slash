//
//  SLHEncoderVP9Options.h
//  Slash
//
//  Created by Terminator on 2019/06/05.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHEncoderVPXOptions.h"

@interface SLHEncoderVP9Options : SLHEncoderVPXOptions

@property NSUInteger tile_columns;
@property NSUInteger tile_rows;
@property NSUInteger frame_parallel;
@property BOOL row_mt;

@end
