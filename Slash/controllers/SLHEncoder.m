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
    SLHEncoderItem *_encoderItem;
    BOOL _inProgress;
    BOOL _paused;
    
    IBOutlet NSTextField *_statusLineTextField;
    IBOutlet NSProgressIndicator *_progressBar;
    
    Encoder *_enc;
    Queue *_queue;
}

@property BOOL inProgress;
@property double progressBarMaxValue;

@end

@implementation SLHEncoder

- (instancetype)init
{
    self = [super init];
    if (self) {
        _enc = malloc(sizeof(Encoder));
        encoder_init(_enc, (char *[]) {"", NULL});
        
        _queue = malloc(sizeof(Queue));
        queue_init(_queue, (void *)args_free);
    }
    return self;
}

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
    
}

- (void)dealloc {
    if (_enc) {
        encoder_destroy(_enc);
        free(_enc);
    }
    
    if (_queue) {
        queue_destroy(_queue);
        free(_queue);
    }
}

#pragma mark - IBActions

- (IBAction)startEncoding:(id)sender {
}

- (IBAction)stopEncoding:(id)sender {
}

#pragma mark - Private

static inline char **_nsarray2carray(NSArray <NSString *> *array) {
    size_t count = array.count;
    char **result = malloc(sizeof(char *) * (count + 1));
    size_t i = 0;
    for (NSString *str in array) {
        result[i++] = strdup(str.UTF8String);
    }
    result[i] = NULL;
    return result;
}

static void _encoder_cb(char *data, void *ctx) {
    
}

static void _encoder_exit_cb(void *ctx, int exit_code) {
    
}

@end
