//
//  SLHEncoder.m
//  Slash
//
//  Created by Terminator on 2019/04/03.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHEncoder.h"

typedef void (^respond_block)(SLHEncoderState);

@interface SLHEncoder () {
    respond_block _block;
    NSError *_error;
}

@end

@implementation SLHEncoder

- (void)encodeItem:(SLHEncoderItem *)item usingBlock:(void (^)(SLHEncoderState))block {
    _block = block;
    
}

- (NSString *)encodingLog {
    return @"";
}

- (NSError *)error {
    return _error;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
