//
//  SLHEncoderVP9Options.m
//  Slash
//
//  Created by Terminator on 2019/06/05.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHEncoderVP9Options.h"

@implementation SLHEncoderVP9Options

- (id)copyWithZone:(NSZone *)zone {
    SLHEncoderVP9Options *obj = [super copyWithZone:zone];
    obj->_tile_columns = _tile_columns;
    obj->_tile_rows = _tile_rows;
    obj->_frame_parallel = _frame_parallel;
    obj->_row_mt = _row_mt;
    return obj;
}

@end
