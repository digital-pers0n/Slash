//
//  SLHEncoderQueue.m
//  Slash
//
//  Created by Terminator on 2019/04/03.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHEncoderQueue.h"
#import "SLHArgumentsViewController.h"
#import "SLHEncoderItem.h"
#import "SLHEncoderQueueItem.h"
#import "SLHPreferences.h"
#import "SLHExternalPlayer.h"
#import "slh_encoder.h"
#import "slh_util.h"
#import "slh_list.h"

#import "MPVPlayerItem.h"
#import "MPVPlayerItemTrack.h"

@interface SLHEncoderQueue () <NSTableViewDelegate, NSSplitViewDelegate, NSWindowDelegate, NSMenuDelegate> {
    
    IBOutlet NSView *_customView;
    IBOutlet SLHArgumentsViewController *_argumentsViewController;
    IBOutlet NSTableView *_tableView;
    IBOutlet NSArrayController *_arrayController;
    IBOutlet NSTextView *_logView;
    IBOutlet NSView *_logViewContainer;
    IBOutlet NSPopover *_popover;
    IBOutlet NSView *_popoverContentView;
    
    SLHExternalPlayer *_player;
    
    /* Encoder */
    Encoder *_encoder;
    Queue *_global_queue;
    Queue *_encoder_queue;
    char *_log;
    ssize_t _log_size;
    dispatch_queue_t _main_thread;
}

@property BOOL inProgress;
@property BOOL paused;
@property BOOL logViewState;

@end

@implementation SLHEncoderQueue

- (NSString *)windowNibName {
    return self.className;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _encoder = malloc(sizeof(Encoder));
        encoder_init(_encoder, (char *[]) { "", NULL });
        
        _global_queue = malloc(sizeof(Queue));
        queue_init(_global_queue, NULL);
        
        _encoder_queue = malloc(sizeof(Queue));
        queue_init(_encoder_queue, (void *)args_free);
        
        _main_thread = dispatch_get_main_queue();
    }
    return self;
}

- (void)dealloc
{
    if (_encoder) {
        encoder_destroy(_encoder);
        free(_encoder);
    }
    
    if (_global_queue) {
        queue_destroy(_global_queue);
        free(_global_queue);
    }
    
    if (_encoder_queue) {
        queue_destroy(_encoder_queue);
        free(_encoder_queue);
    }
    
    if (_log) {
        free(_log);
    }
}

- (void)windowDidLoad {
    [super windowDidLoad];
    NSRect rect = _popoverContentView.frame;
    rect.origin = NSZeroPoint;
    NSView *view =  _argumentsViewController.view;
    view.frame = rect;
    [_popoverContentView addSubview:view];
}

- (void)addEncoderItems:(NSArray<SLHEncoderItem *> *)array {
    [self.window makeKeyAndOrderFront:nil];
    NSMutableArray *objects = [NSMutableArray arrayWithCapacity:array.count];
    
    for (SLHEncoderItem *i in array) {
        SLHEncoderQueueItem *obj = [SLHEncoderQueueItem new];
        obj.encoderArguments = i.encoderArguments;
        obj.name = i.outputPath;
        
        NSInteger streamIdx = i.videoStreamIndex;
        if (streamIdx > -1) {
            TimeInterval interval = i.interval;
            MPVPlayerItemTrack *t = i.playerItem.tracks[streamIdx];
            obj.numberOfFrames = (interval.end - interval.start) * t.averageFrameRate;
        }
        [objects addObject:obj];
    }
    [_arrayController addObjects:objects];
}

#pragma mark - IBActions

- (IBAction)showPopover:(NSButton *)sender {
    if (_popover.shown) {
        [_popover close];
        return;
    }

    [_popover showRelativeToRect:sender.bounds ofView:sender preferredEdge:NSRectEdgeMinY];

    if (_logViewContainer.superview) {
        [_logView scrollToEndOfDocument:nil];
    }
}

- (IBAction)closePopover:(id)sender {
    [_popover close];
}

- (IBAction)startEncoding:(id)sender {
    [self prepareGlobalQueue];
    
    if (queue_size(_global_queue) == 0) {   // Check if the global queue is not empty
        NSBeep();
        return;
    }
    
    [self prepareEncoderQueue];
    
    if ([self encode] == 0) {
        self.inProgress = YES;
        if (!_logViewContainer.superview) {
            _showLog(self);
            self.logViewState = YES;
        }
    }
}

- (IBAction)pauseEncoding:(id)sender {
    BOOL value = (_paused) ? NO : YES;
    encoder_pause(_encoder, value);
    _paused = value;
}

- (IBAction)stopEncoding:(id)sender {
    self.inProgress = NO;
    _paused = NO;
    encoder_stop(_encoder);
}

- (IBAction)removeAll:(id)sender {
    [_arrayController removeObjects:_arrayController.arrangedObjects];
}

- (IBAction)toggleLogView:(id)sender {
    
    if (_logViewContainer.superview) {
        NSView *view = _argumentsViewController.view;
        view.frame = _logViewContainer.frame;
        [_popoverContentView replaceSubview:_logViewContainer with:view];
    } else {
        _showLog(self);
    }
}

- (IBAction)revealInFinder:(id)sender {
    NSInteger idx = _tableView.clickedRow;
    if (idx > -1) {
        SLHEncoderQueueItem *queueItem = _arrayController.arrangedObjects[idx];
        if (queueItem.encoded) {
            NSWorkspace *sharedWorkspace = [NSWorkspace sharedWorkspace];
            [sharedWorkspace selectFile:queueItem.name inFileViewerRootedAtPath:@""];
        }
    }
}

- (IBAction)previewSelected:(id)sender {
    NSInteger idx = _tableView.clickedRow;
    if (idx > -1) {
        SLHEncoderQueueItem *queueItem = _arrayController.arrangedObjects[idx];
        if (queueItem.encoded) {
            if (!_player) {
                _player = [SLHExternalPlayer defaultPlayer];
                if (_player.error) {
                    NSLog(@"%s: Playback error: %@", __PRETTY_FUNCTION__, _player.error.localizedDescription);
                    _player = nil;
                    return;
                }
            }
            _player.url = [NSURL fileURLWithPath:queueItem.name isDirectory:NO];
            [_player orderFront];
            
            [_player play];
        }
    }
}

- (IBAction)removeSelected:(id)sender {
    NSInteger idx = _tableView.clickedRow;
    if (idx > -1) {
        SLHEncoderQueueItem *queueItem = _arrayController.arrangedObjects[idx];
        [_arrayController removeObject:queueItem];
    }
}

static inline void _showLog(SLHEncoderQueue *obj) {
    NSView *view = obj->_argumentsViewController.view;
    obj->_logViewContainer.frame = view.frame;;
    [obj->_popoverContentView replaceSubview:view with:obj->_logViewContainer];
    [obj->_logView scrollToEndOfDocument:nil];
}

#pragma mark - Private

- (void)prepareGlobalQueue {
    if (queue_size(_global_queue)) {
        queue_destroy(_global_queue);
        queue_init(_global_queue, NULL);
    }
    NSArray *items = _arrayController.arrangedObjects;
    for (SLHEncoderQueueItem *item in items) {
        if (!item.encoded) {
            queue_enqueue(_global_queue, (__bridge const void *)(item));
        }
    }
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

- (void)prepareEncoderQueue {
    if (queue_size(_global_queue) == 0) {
        return;     // nothing to be done;
    }
    SLHEncoderQueueItem *item = (__bridge id)(queue_peek(_global_queue));
    if (item) {
        if (queue_size(_encoder_queue)) {
            queue_destroy(_encoder_queue);
            queue_init(_encoder_queue, (void *)args_free);
        }
        NSArray *args = item.encoderArguments;
        for (NSArray *a in args) {
            char **array = _nsarray2carray(a);
            queue_enqueue(_encoder_queue, array);
        }
    }
}

static inline uint64_t _get_frame_number(const char *str) {
    
    const char frame[] = "frame=";

    char *s = strstr(str, frame);
    if (s) {
        return strtoul(s + (sizeof(frame) - 1), 0, 10);
    }
    
    return 0;
}

static void _encoder_callback(char *data, void *ctx, ssize_t data_len) {
    __unsafe_unretained SLHEncoderQueue *obj = (__bridge id)ctx;
    if (data_len < 256) {
        uint64_t frame_number = _get_frame_number(data);
        dispatch_async(obj->_main_thread, ^{
            SLHEncoderQueueItem *item = (__bridge id)queue_peek(obj->_global_queue);
            item.currentFrameNumber = frame_number;
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

static void _encoder_exit_callback(void *ctx, int exit_code) {
    SLHEncoderQueue *obj = (__bridge id)ctx;
    SLHEncoderQueueItem *item = (__bridge id)queue_peek(obj->_global_queue);
    
    void *ptr;
    queue_dequeue(obj->_encoder_queue, &ptr);
    args_free(ptr);
    
    if (queue_size(obj->_encoder_queue)) { // second pass
        dispatch_async(obj->_main_thread, ^{
            item.log = [NSString stringWithFormat:@"%s\n\n=== Second Pass ===\n\n", obj->_log];
            [obj encode];
        });
        return;
    }
    
    dispatch_async(obj->_main_thread, ^{
        // Check exit code
        if (exit_code == 0) {
            item.encoded = YES;
            item.failed = NO;
        } else {
            item.encoded = NO;
            item.failed = YES;
        }
    });
    
    // Append log
    dispatch_sync(obj->_main_thread, ^{
        NSString *str = item.log;
        if (str) {
            item.log = [str stringByAppendingString:@(obj->_log)];
        } else {
            item.log = @(obj->_log);
        }
    });
    
    if (queue_size(obj->_global_queue)) { // load next item
        // dequeue previous item
        void *ptr;
        queue_dequeue(obj->_global_queue, &ptr);
        
        // Check if the queue is not empty and encoding wasn't stopped
        if (queue_size(obj->_global_queue) && exit_code != SIGKILL) {
            dispatch_async(obj->_main_thread, ^{
                [obj prepareEncoderQueue];
                [obj encode];
            });
            return;
        }
    }
    if (exit_code == SIGKILL || queue_size(obj->_global_queue) == 0) {
        dispatch_async(obj->_main_thread, ^{
            obj.inProgress = NO;
        });
    }
}

- (int)encode {
        
    if (_log) {
        free(_log);
    }
    _log_size = 0;
    _log = malloc(sizeof(char));
    _log[0] = '\0';
    
    char **args = queue_peek(_encoder_queue);
    encoder_set_args(_encoder, args);
    if (encoder_start(_encoder, _encoder_callback, _encoder_exit_callback, (__bridge void *)self)) {
        NSLog(@"%s: encoder_start() cannot start encoding", __PRETTY_FUNCTION__);
        return -1;
    }
    self.inProgress = YES;
    return 0;
}

#pragma mark - NSTableView Delegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger row = _tableView.selectedRow;
    if (row > -1) {
        id item = _arrayController.arrangedObjects[row];
        _argumentsViewController.encoderItem = item;
        
        if (_logViewContainer.superview) {
            [_logView scrollToEndOfDocument:nil];
        }
    }
}

#pragma mark - NSWindowDelegate

- (BOOL)windowShouldClose:(id)sender {
    return (_inProgress) ? NO : YES;
}

- (void)windowWillClose:(NSNotification *)notification {
    // Remove encoded items automatically
    NSArray *allItems = _arrayController.arrangedObjects;
    NSMutableArray *toRemove = NSMutableArray.new;
    for (SLHEncoderQueueItem *item in allItems) {
        if (item.encoded) {
            [toRemove addObject:item];
        }
    }
    if (toRemove.count) {
        [_arrayController removeObjects:toRemove];
    }
}

#pragma mark - NSMenuDelegate

- (void)menuNeedsUpdate:(NSMenu *)menu {
    NSInteger idx = _tableView.clickedRow;
    if (idx > -1 && !(_inProgress)) {
        SLHEncoderQueueItem *queueItem = _arrayController.arrangedObjects[idx];
        NSArray *menuItems = menu.itemArray;
        for (NSMenuItem *menuItem in menuItems) {
            if (menuItem.tag == 100) {
                menuItem.enabled = queueItem.encoded;
            } else {
                menuItem.enabled = YES;
            }
        }
    } else {
        NSArray *menuItems = menu.itemArray;
        for (NSMenuItem *menuItem in menuItems) {
            menuItem.enabled = NO;
        }
    }
}

@end
