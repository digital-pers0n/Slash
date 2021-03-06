//
//  SLHEncoder.m
//  Slash
//
//  Created by Terminator on 2019/04/03.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHEncoder.h"
#import "SLHEncoderItem.h"
#import "SLHStatusLineView.h"
#import "slh_encoder.h"
#import "slh_util.h"
#import "slh_list.h"

#import "MPVPlayerItem.h"
#import "MPVPlayerItemTrack.h"

typedef void (^respond_block)(SLHEncoderState);

@interface SLHEncoder () <NSWindowDelegate> {
    respond_block _block;
    NSError *_error;
    SLHEncoderItem *_encoderItem;
    BOOL _inProgress;
    BOOL _paused;
    
    IBOutlet SLHStatusLineView *_statusLineView;
    IBOutlet NSProgressIndicator *_progressBar;
    IBOutlet NSButton *_pauseButton;
    
    Encoder *_enc;
    Queue *_queue;
    char *_log;
    ssize_t _log_size;
    dispatch_queue_t _main_thread;
    CFRunLoopRef _main_rl;
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
        _main_rl = CFRunLoopGetMain();
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
    NSInteger streamIndex = item.videoStreamIndex;
    if (streamIndex != -1) {
        MPVPlayerItemTrack *track = item.playerItem.tracks[streamIndex];
        TimeInterval interval = item.interval;
        self.progressBarMaxValue = track.averageFrameRate * (interval.end - interval.start);
    } else {
        self.progressBarMaxValue = 1;
    }
    NSWindow *window = self.window;
    [window center];
    [window setTitleWithRepresentedFilename:item.outputPath];
    [self startEncoding];
    [NSApp runModalForWindow:window];
    [NSApp stopModal];
    [window orderOut:nil];
    
}

- (void)windowWillClose:(NSNotification *)notification {
    [self stopEncoding:nil];
    [NSApp stopModal];
}

- (NSString *)encodingLog {
    return @(_log);
}

- (NSError *)error {
    return _error;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    _statusLineView.wantsLayer = YES;
    
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

- (void)startEncoding {
    if (queue_size(_queue) == 0) {
        return;
    }
    _statusLineView.string = @"Encoding...";
    if (_log) {
        free(_log);
    }
    _log_size = 0;
    _log = malloc(sizeof(char));
    _log[0] = '\0';
    char **args = queue_peek(_queue);
    encoder_set_args(_enc, args);
    if (encoder_start(_enc, _encoder_cb, _encoder_exit_cb, (__bridge void *)(self))) {
        _statusLineView.string = @"Error";
    }
    self.inProgress = YES;
}

#pragma mark - IBActions

- (IBAction)pauseEncoding:(id)sender {
    BOOL value = (_paused) ? NO : YES;
    encoder_pause(_enc, value);
    _paused = value;
}

- (IBAction)stopEncoding:(id)sender {
    self.inProgress = NO;
    _paused = NO;
    encoder_stop(_enc);
}

#pragma mark - Private

/** 
 Get the number of already encoded frames.
 Set @c s to a location inside @c data, that is ready to be displayed in the statusLine view
 
 @note If @c data cannot be parsed, then @c s is left untouched
 */
static inline uint64_t _get_frames(const char *data, char **s) {

    const char frame[] = "frame=";
    char *found = strstr(data, frame);
    if (found) {
        *s = found;
        return strtoul(found + (sizeof(frame) - 1), 0, 10);
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

static void _encoder_cb(char *data, void *ctx, ssize_t data_len) {
    __unsafe_unretained SLHEncoder *obj = (__bridge id)ctx;
    
    if (data_len < 192) {
        char *string = data;
        uint64_t frames = _get_frames(data, &string);
        CFStringRef st = CFStringCreateWithCString(kCFAllocatorDefault,
                                                   string,
                                                   kCFStringEncodingUTF8);
        CFRunLoopPerformBlock(obj->_main_rl, kCFRunLoopCommonModes, ^{
            obj->_progressBar.doubleValue = frames;
            obj->_statusLineView.string = CFBridgingRelease(st);
        });
    
    } else {

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
    dispatch_sync(obj->_main_thread, ^{
        obj.inProgress = NO;
    });
    obj->_paused = NO;
    NSString *statusString = @"";
    if (exit_code == 0) {
        void *ptr;
        queue_dequeue(obj->_queue, &ptr);
        args_free(ptr);
        if (queue_size(obj->_queue)) {
            dispatch_async(obj->_main_thread, ^{
                [obj startEncoding];
            });
        } else {
            dispatch_sync(obj->_main_thread, ^{
                obj->_block(SLHEncoderStateSuccess);
            });
        }
    } else {
        SLHEncoderState state;
        if (exit_code == SIGKILL) {
            state = SLHEncoderStateCanceled;
            statusString = @"Canceled";
        } else {
            state  = SLHEncoderStateFailed;
            statusString = @"Error";
        }
        dispatch_sync(obj->_main_thread, ^{
            obj->_block(state);
        });
    }
    dispatch_sync(obj->_main_thread, ^{
        obj->_statusLineView.string = statusString;
        obj->_pauseButton.state = NSControlStateValueOff;
    });
    
#ifdef DEBUG
    puts(obj->_log);
    printf("==========================================\n Exit Code: %i\n", exit_code);
#endif
    
}

@end
