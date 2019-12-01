//
//  SLHTrimTableCellView.m
//  Slash
//
//  Created by Terminator on 2019/11/06.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHTrimTableCellView.h"
#import "SLHTrimView.h"
#import "SLHEncoderItem.h"
#import "MPVPlayerItem.h"

@implementation SLHTrimTableCellView

- (void)setObjectValue:(id)objectValue {
    if (!objectValue) { return; }

    SLHEncoderItem *obj = objectValue;
    
    [_trimView bind:@"maxValue" toObject:obj withKeyPath:@"playerItem.duration" options:nil];
        [_trimView bind:@"endValue" toObject:obj withKeyPath:@"intervalEnd" options:nil];
    [_trimView bind:@"startValue" toObject:obj withKeyPath:@"intervalStart" options:nil];
    [_outNameTextField bind:@"stringValue" toObject:obj withKeyPath:@"outputFileName" options:nil];

    _trimView.maxValue = obj.playerItem.duration;
    _trimView.endValue = obj.intervalEnd;
    _trimView.startValue = obj.intervalStart;
    
    [super setObjectValue:objectValue];
 
}

- (void)dealloc {

    [_trimView unbind:@"startValue"];
    [_trimView unbind:@"endValue"];
    [_trimView unbind:@"maxValue"];
    [_outNameTextField unbind:@"stringValue"];
}

- (void)prepareForReuse {

    [_trimView prepareForReuse];
    [_outNameTextField prepareForReuse];
    [super prepareForReuse];
}

@end
