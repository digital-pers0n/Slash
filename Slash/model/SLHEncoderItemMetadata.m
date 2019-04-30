//
//  SLHEncoderMetadata.m
//  Slash
//
//  Created by Terminator on 2019/04/30.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHEncoderItemMetadata.h"

@implementation SLHEncoderItemMetadata

- (id)copyWithZone:(NSZone *)zone {
    SLHEncoderItemMetadata *item = [[self.class allocWithZone:zone] init];
    item->_artist = _artist.copy;
    item->_title = _title.copy;
    item->_date = _date.copy;
    item->_comment = _comment.copy;
    return item;
}

- (NSArray<NSString *> *)arguments {
    NSMutableArray *args = [NSMutableArray new];
    if (_title) {
        [args addObject:@"-metadata"];
        [args addObject:[NSString stringWithFormat:@"title=%@", _title]];
    }
    if (_artist) {
        [args addObject:@"-metadata"];
        [args addObject:[NSString stringWithFormat:@"artist=%@", _artist]];
    }
    if (_date) {
        [args addObject:@"-metadata"];
        [args addObject:[NSString stringWithFormat:@"date=%@", _date]];
    }
    if (_comment) {
        [args addObject:@"-metadata"];
        [args addObject:[NSString stringWithFormat:@"comment=%@", _comment]];
    }
    return args;
}


@end
