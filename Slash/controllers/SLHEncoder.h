//
//  SLHEncoder.h
//  Slash
//
//  Created by Terminator on 2019/04/03.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SLHEncoderItem;
typedef NS_ENUM(NSUInteger, SLHEncoderState) {
    SLHEncoderStateSuccess,
    SLHEncoderStateFailed,
    SLHEncoderStateCanceled,
};
@interface SLHEncoder : NSWindowController

- (void)encodeItem:(SLHEncoderItem *)item usingBlock:(void (^)(SLHEncoderState state))block;

/**
 Output of the ffmpeg command
 */
- (NSString *)encodingLog;

- (NSError *)error;

@end