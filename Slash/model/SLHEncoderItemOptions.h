//
//  SLHEncoderItemOptions.h
//  Slash
//
//  Created by Terminator on 2019/03/01.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SLHEncoderItemOptions : NSObject <NSCopying>

- (instancetype)initWithOptions:(SLHEncoderItemOptions *)options;

@property NSString *codecName;

@property BOOL scale;
@property NSUInteger videoWidth;
@property NSUInteger videoHeight;

@property NSUInteger bitRate;
@property NSUInteger maxBitrate;
@property NSUInteger crf;
@property NSUInteger maxGopSize;
@property (nonatomic) NSUInteger quality;

@property NSUInteger sampleRate;
@property NSUInteger numberOfChannels;
@end
