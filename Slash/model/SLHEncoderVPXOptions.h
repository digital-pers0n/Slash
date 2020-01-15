//
//  SLHEncoderVPXOptions.h
//  Slash
//
//  Created by Terminator on 2019/05/27.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHEncoderItemOptions.h"

typedef NS_ENUM(NSUInteger, SLHVPXQualityType) {
    SLHVPXQualityBest,
    SLHVPXQualityGood,
    SLHVPXQualityRealtime,
    SLHVPXQualityAuto = NSUIntegerMax
};

@interface SLHEncoderVPXOptions : SLHEncoderItemOptions

@property BOOL twoPass;
@property BOOL enableCRF;
@property SLHVPXQualityType vpxQuality;
@property NSInteger speed;
@property NSUInteger lagInFrames; //0 - 25
@property BOOL enableAltRef;

@end
