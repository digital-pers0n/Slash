//
//  SLHEncoder.m
//  Slash
//
//  Created by Terminator on 2019/04/03.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHEncoder.h"
#import "SLHEncoderItem.h"
#import "SLHMediaItem.h"
#import "SLHMediaItemTrack.h"
#import "slh_encoder.h"
#import "slh_util.h"
#import "slh_list.h"

typedef void (^respond_block)(SLHEncoderState);

@interface SLHEncoder () <NSWindowDelegate> {
    respond_block _block;
    NSError *_error;
    SLHEncoderItem *_encoderItem;
    BOOL _inProgress;
    BOOL _paused;
    BOOL _canceled;
    
    IBOutlet NSTextField *_statusLineTextField;
    IBOutlet NSProgressIndicator *_progressBar;
    IBOutlet NSButton *_pauseButton;
    
    Encoder *_enc;
    Queue *_queue;
    char *_log;
    size_t _log_size;
    dispatch_queue_t _main_thread;
}

@property BOOL inProgress;
@property BOOL paused;
@property double progressBarMaxValue;

@end

@implementation SLHEncoder

- (NSString *)windowNibName {
    return self.className;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _enc = malloc(sizeof(Encoder));
        encoder_init(_enc, (char *[]) {"", NULL});
        
        _queue = malloc(sizeof(Queue));
        queue_init(_queue, (void *)args_free);
        
        _main_thread = dispatch_get_main_queue();
    }
    return self;
}

- (void)encodeItem:(SLHEncoderItem *)item usingBlock:(void (^)(SLHEncoderState))block {
    _block = [block copy];
    NSArray *args = item.encoderArguments;
    
    // Clear the queue
    if (queue_size(_queue)) {
        queue_destroy(_queue);
        queue_init(_queue, (void *)args_free);
    }

    for (NSArray *a in args) {
        char **array = _nsarray2carray(a);
        queue_enqueue(_queue, array);
    }
    if (item.videoStreamIndex != -1) {
        SLHMediaItem *mediaItem = item.mediaItem;
        for (SLHMediaItemTrack *t in mediaItem.tracks) {
            if (t.mediaType == SLHMediaTypeVideo) {
                self.progressBarMaxValue = t.frameRate * (item.interval.end - item.interval.start);
                break;
            }
        }
    } else {
        self.progressBarMaxValue = 1;
    }
    NSWindow *window = self.window;
    [window center];
    [NSApp runModalForWindow:window];
    [NSApp endSheet:window];
    [window orderOut:nil];
    
}

- (void)windowWillClose:(NSNotification *)notification {
    [NSApp endSheet:self.window];
}

- (NSString *)encodingLog {
    return @(_log);
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
    
    if (_log) {
        free(_log);
    }
}

#pragma mark - IBActions

- (IBAction)startEncoding:(id)sender {
    if (queue_size(_queue)) {
        if (_log) {
            free(_log);
        }
        _log_size = 0;
        _log = malloc(sizeof(char));
        _log[0] = '\0';
        char **args = queue_peek(_queue);
        encoder_set_args(_enc, args);
        if (encoder_start(_enc, _encoder_cb, _encoder_exit_cb, (__bridge void *)(self))) {
            _statusLineTextField.stringValue = @"Error";
        }
        self.inProgress = YES;
    }
}

- (IBAction)pauseEncoding:(id)sender {
    BOOL value = (_paused) ? NO : YES;
    encoder_pause(_enc, value);
    _paused = value;
}

- (IBAction)stopEncoding:(id)sender {
    self.inProgress = NO;
    _paused = NO;
    _canceled = YES;
    encoder_stop(_enc);
}

#pragma mark - Private

static inline uint64_t _get_frames(const char *str) {
    
    char *s = strstr(str, "frame=");
    if (s) {
        return strtoul(s + 6, 0, 10);
    }
    
    return 0;
}

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
    uint64_t frames = 0;
    SLHEncoder *obj = (__bridge id)ctx;
    if ((frames = _get_frames(data))) {
        
        dispatch_sync(obj->_main_thread, ^{
            obj->_progressBar.doubleValue = frames;
            obj->_statusLineTextField.stringValue = [NSString stringWithFormat:@"%llu of %.0f frames", frames, obj->_progressBarMaxValue];
        });
    } else {
        size_t data_len = ENCODER_BUFFER_SIZE;
        obj->_log_size += data_len;
        char *tmp = realloc(obj->_log, (obj->_log_size * sizeof(char)) + 1);
        if (tmp) {
            strncat(tmp, data, data_len);
            obj->_log = tmp;
        }
    }
}

static void _encoder_exit_cb(void *ctx, int exit_code) {
    SLHEncoder *obj = (__bridge id)ctx;
    obj.inProgress = NO;
    obj->_paused = NO;
    NSString *statusString = @"";
    if (exit_code == 0) {
        obj->_block(SLHEncoderStateSuccess);
        void *ptr;
        queue_dequeue(obj->_queue, &ptr);
        args_free(ptr);
    } else {
        if (obj->_canceled) {
            obj->_canceled = NO;
            obj->_block(SLHEncoderStateCanceled);
            statusString = @"Canceled";
        } else {
            obj->_block(SLHEncoderStateFailed);
            statusString = @"Error";
        }
    }
    dispatch_sync(obj->_main_thread, ^{
        obj->_statusLineTextField.stringValue = statusString;
        obj->_pauseButton.state = NSOffState;
    });


}

@end
