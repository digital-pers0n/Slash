//
//  SLHEncoder.m
//  Slash
//
//  Created by Terminator on 2019/04/03.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHEncoder.h"
#import "SLHEncoderItem.h"
#import "slh_encoder.h"

typedef void (^respond_block)(SLHEncoderState);

@interface SLHEncoder () {
    respond_block _block;
    NSError *_error;
    IBOutlet NSTextField *_statusLineTextField;
    
    Encoder *_enc;
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
    _enc = malloc(sizeof(Encoder));
    encoder_init(_enc, (char *[]) {"", NULL});
    
}

- (void)dealloc {
    if (_enc) {
        encoder_destroy(_enc);
        free(_enc);
    }
}

#pragma mark - IBActions

- (IBAction)startEncoding:(id)sender {
}

- (IBAction)stopEncoding:(id)sender {
}

#pragma mark - Private

static void _encoder_cb(char *data, void *ctx) {
    
}

static void _encoder_exit_cb(void *ctx, int exit_code) {
    
}

@end
