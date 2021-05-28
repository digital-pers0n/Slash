//
//  MPVPlayer.m
//  Slash
//
//  Created by Terminator on 2019/10/12.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "MPVPlayer.h"
#import "MPVPlayerItem.h"
#import "MPVPlayerProperties.h"
#import "MPVPlayerCommands.h"
#import "MPVBase.h"
#import "MPVKitDefines.h"

#define mpv_print_error_set_property(error_code, property_name, value_format, value) \
NSLog(@"%s Failed to set value '" value_format "' for property '%@' -> %d %s", \
__PRETTY_FUNCTION__, value, property_name, error_code, mpv_error_string(error_code))

#define mpv_print_error_get_property(error_code, property_name) \
NSLog(@"%s Failed to get value for property '%@' -> %d %s", \
__PRETTY_FUNCTION__, property_name, error_code, mpv_error_string(error_code))

#define mpv_print_error_generic(error_code, format, ...) \
NSLog(@"%s " format " -> %d %s", \
__PRETTY_FUNCTION__, ##__VA_ARGS__, error_code, mpv_error_string(error_code))

static inline void check_error(int status) {
    if (status < 0) {
        printf("mpv API error: %s\n", mpv_error_string(status));
    }
}

OBJC_DIRECT_MEMBERS
@interface NSPointerArray(MPVPlayerAdditions)
+ (instancetype)arrayWithObject:(id)value;
- (BOOL)containsObject:(id)object;
- (void)addObject:(id)object;
- (void)removeObject:(id)object;
- (NSUInteger)indexOfObject:(id)object;
@end

@implementation NSPointerArray(MPVPlayerAdditions)

+ (instancetype)arrayWithObject:(id)value {
    NSPointerArray *result = [NSPointerArray pointerArrayWithOptions:
                              (NSPointerFunctionsOpaqueMemory |
                               NSPointerFunctionsOpaquePersonality)];
    [result addObject:value];
    return result;
}

- (BOOL)containsObject:(id)value {
    if (!value) return NO;
    for (id element in self) {
        if (element == value) {
            return YES;
        }
    }
    return NO;
}

- (void)addObject:(id)value {
    [self addPointer:(__bridge void *)value];
}

- (void)removeObject:(id)value {
    NSUInteger idx = [self indexOfObject:value];
    if (idx != NSNotFound) {
        [self removePointerAtIndex:idx];
        [self compact];
    }
}

- (NSUInteger)indexOfObject:(id)value {
    if (!value) return NSNotFound;
    NSUInteger result = 0;
    BOOL found = NO;

    for (id element in self) {
        if (element == value) {
            found = YES;
            break;
        }
        result++;
    }
    if (!found) {
        return NSNotFound;
    }
    return result;
}

@end

typedef NS_ENUM(NSInteger, MPVPlayerEvent) {
    MPVPlayerEventStartFile,
    MPVPlayerEventEndFile,
    MPVPlayerEventFileLoaded,
    MPVPlayerEventIdle,
    MPVPlayerEventVideoReconfig,
    MPVPlayerEventSeek,
    MPVPlayerEventPlaybackRestart,
    MPVPlayerEventNone
};

@interface MPVPlayer () {
    MPVPlayerItem *_currentItem;
    NSThread *_eventThread;
    NSMutableDictionary *_observed; ///< Observed Properties
}
- (void)readEvents;
@end

OBJC_DIRECT_MEMBERS
@implementation MPVPlayer

- (instancetype)initWithBlock:(void (^)(__weak MPVPlayer *))block {
    self = [super init];
    if (self) {
        __unsafe_unretained typeof(self) wSelf = self;
        int error = [self setUpUsingBlock:^{
            [wSelf loadDefaultOptions];
            block(wSelf);
        }];
        
        if (error != MPV_ERROR_SUCCESS) {
            _status = MPVPlayerStatusFailed;
        } else {
            _status = MPVPlayerStatusReadyToPlay;
            [self postInit];
        }
    }
    return self;
}

- (instancetype)initWithOptions:(NSDictionary<NSString *,NSString *> *)options {
    self = [super init];
    if (self) {
        __unsafe_unretained typeof(self) ref = self;
        int error = [self setUpUsingBlock:^{
            [ref loadDefaultOptions];
            [ref loadOptions:options];
        }];
        
        if (error != MPV_ERROR_SUCCESS) {
            _status = MPVPlayerStatusFailed;
        } else {
            _status = MPVPlayerStatusReadyToPlay;
            [self postInit];
        }

    }
    return self;
}

- (instancetype)initWithConfig:(NSString *)path {
    self = [super init];
    if (self) {
        __unsafe_unretained typeof(self) ref = self;
        int error = [self setUpUsingBlock:^{
            [ref loadDefaultOptions];
            int error = [ref loadConfig:path];
            if (error != MPV_ERROR_SUCCESS) {
                NSLog(@"Failed to read '%@' config file.", path);
            }
        }];
        
        if (error != MPV_ERROR_SUCCESS) {
            _status = MPVPlayerStatusFailed;
        } else {
            _status = MPVPlayerStatusReadyToPlay;
            [self postInit];
        }
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        __unsafe_unretained typeof(self) ref = self;
        int error = [self setUpUsingBlock:^{
            [ref loadDefaultOptions];
        }];
        
        if (error != MPV_ERROR_SUCCESS) {
            _status = MPVPlayerStatusFailed;
        } else {
            _status = MPVPlayerStatusReadyToPlay;
            [self postInit];
        }
    }
    return self;
}

- (int)createMPVHandle {
    mpv_handle *mpv = mpv_create();
    if (!mpv) {
        
        NSLog(@"Cannot create mpv_handle.");
        
        _error = [[NSError alloc]
                  initWithDomain:MPVPlayerErrorDomain
                  code:MPV_ERROR_GENERIC
                  userInfo:@{NSLocalizedDescriptionKey : @"Cannot create mpv_handle." }];
        return MPV_ERROR_GENERIC;
    }
    _mpv_handle = mpv;
    return MPV_ERROR_SUCCESS;
}

- (int)initializeMPVHandle {
    int error = mpv_initialize(_mpv_handle);
    if (error < 0) {
        
        NSLog(@"Cannot initialize mpv_handle.");
        
        _error = [[NSError alloc]
                  initWithDomain:MPVPlayerErrorDomain
                  code:error
                  userInfo:@{ NSLocalizedDescriptionKey :
                                  [NSString stringWithFormat:@"%s\n", mpv_error_string(error)]
                              }];
        mpv_destroy(_mpv_handle);
        _mpv_handle = nil;
        return error;
    }
    return MPV_ERROR_SUCCESS;
}

- (void)startEventListener {
    _eventThread = [[NSThread alloc] initWithTarget:self selector:@selector(readEvents) object:nil];
    _eventThread.qualityOfService = NSQualityOfServiceUserInteractive;
    _eventThread.name = @"com.home.mpvPlayer.EventThread";
    [_eventThread start];
}

- (void)loadDefaultOptions {
    [self setString:@"videotoolbox" forProperty:@"hwdec"];
    
    #ifdef ENABLE_LEGACY_GPU_SUPPORT
    [self setString:@"uyvy422" forProperty:@"hwdec-image-format"];
    #endif
    
    [self setBool:YES forProperty:@"input-default-bindings"];
    [self setBool:YES forProperty:@"keep-open"];
    [self setString:@"libmpv" forProperty:@"vo"];
}

- (int)loadConfig:(NSString *)path {
    int error = mpv_load_config_file(_mpv_handle, path.UTF8String);
    if (error < 0) {
        
        NSLog(@"Cannot load config file %@", path);
        
        _error = [[NSError alloc]
                  initWithDomain:MPVPlayerErrorDomain
                  code:error
                  userInfo:@{ NSLocalizedDescriptionKey :
                                  [NSString stringWithFormat:@"%s\n", mpv_error_string(error)]
                              }];
        return error;
    }
    return MPV_ERROR_SUCCESS;
}

- (void)loadOptions:(NSDictionary *)options {
    [options enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [self setString:obj forProperty:key];
    }];
}

- (int)setUpUsingBlock:(void (^)(void))block {
    int error = [self createMPVHandle];
    if (error != MPV_ERROR_SUCCESS) {
        return error;
    }
    
    block();
    
#ifdef DEBUG
    check_error( mpv_request_log_messages(_mpv_handle, "info") );
#else
    check_error( mpv_request_log_messages(_mpv_handle, "error") );
#endif
    
    return [self initializeMPVHandle];
}

- (void)postInit {
    _observed = [NSMutableDictionary new];
    [self startEventListener];
}

- (void)dealloc
{
    if (_status == MPVPlayerStatusReadyToPlay) {
        [self shutdown];
    }
}

- (void)readEvents {
@autoreleasepool {
    NSNotification * __autoreleasing notifications[MPVPlayerEventNone] = {
    [NSNotification notificationWithName:MPVPlayerWillStartPlaybackNotification
                                  object:self userInfo:nil],
    [NSNotification notificationWithName:MPVPlayerDidEndPlaybackNotification
                                  object:self userInfo:nil],
    [NSNotification notificationWithName:MPVPlayerDidLoadFileNotification
                                  object:self userInfo:nil],
    [NSNotification notificationWithName:MPVPlayerDidEnterIdleModeNotification
                                  object:self userInfo:nil],
    [NSNotification notificationWithName:MPVPlayerVideoDidChangeNotification
                                  object:self userInfo:nil],
    [NSNotification notificationWithName:MPVPlayerDidStartSeekNotification
                                  object:self userInfo:nil],
    [NSNotification notificationWithName:MPVPlayerDidRestartPlaybackNotification
                                  object:self userInfo:nil]
    };
    CFRunLoopRef main_rl = CFRunLoopGetMain();
    MPVPlayerEvent playerEvent = MPVPlayerEventNone;
    NSNotificationCenter *tmp = NSNotificationCenter.defaultCenter;
    
    // Cache -[NSNotificationCenter postNotification:] method
    typedef void (*IMP_f)(void * _Nonnull, SEL _Nonnull, void * _Nonnull);
    const SEL postNotification = @selector(postNotification:);
    const IMP_f cachedMethod = (IMP_f)[tmp methodForSelector:postNotification];
    void *notificationCenter = (__bridge void *)tmp;
    
    while (!_eventThread.cancelled) {
        mpv_event *event = mpv_wait_event(_mpv_handle, -1);
        switch (event->event_id) {
                
            case MPV_EVENT_NONE:
                goto exit;
                
            case MPV_EVENT_SHUTDOWN:
            {
                if (_status == MPVPlayerStatusReadyToPlay) {
                    CFRunLoopPerformBlock(main_rl, kCFRunLoopCommonModes, ^{
                        [self shutdown];
                    });
                }
            }
                goto exit;
                
            case MPV_EVENT_LOG_MESSAGE:
                mpv_print_log_message(event->data);
                break;
                
            case MPV_EVENT_START_FILE:
                playerEvent = MPVPlayerEventStartFile;
                break;
                
            case MPV_EVENT_END_FILE:
                playerEvent = MPVPlayerEventEndFile;
                break;
                
            case MPV_EVENT_FILE_LOADED:
                playerEvent = MPVPlayerEventFileLoaded;
                break;
                
            case MPV_EVENT_IDLE:
                playerEvent = MPVPlayerEventIdle;
                break;
                
            case MPV_EVENT_VIDEO_RECONFIG:
                playerEvent = MPVPlayerEventVideoReconfig;
                break;
                
            case MPV_EVENT_SEEK:
                playerEvent = MPVPlayerEventSeek;
                break;
                
            case MPV_EVENT_PLAYBACK_RESTART:
                playerEvent = MPVPlayerEventPlaybackRestart;
                break;
                
            case MPV_EVENT_PROPERTY_CHANGE:
                [self notifyObservers:event->data];
                break;
                
            default:
                printf("event: %s\n", mpv_event_name(event->event_id));
                break;
        }
        
        if (playerEvent != MPVPlayerEventNone) {

#ifdef DEBUG
            NSLog(@"%@: Post '%@'.", self, notifications[playerEvent].name);
#endif
            void *n = (__bridge void *)notifications[playerEvent];
            CFRunLoopPerformBlock(main_rl, kCFRunLoopCommonModes, ^{
                cachedMethod(notificationCenter, postNotification, n);
            });
            playerEvent = MPVPlayerEventNone;
        }
    }
    
exit:
#ifdef DEBUG
    NSLog(@"%@: Exit event thread", self);
#endif
    dispatch_sync(dispatch_get_main_queue(), ^{
        CFRunLoopWakeUp(main_rl);
    });
}
}

- (void)shutdown {
    if (!_eventThread.cancelled) {
        [_eventThread cancel];
        mpv_wakeup(_mpv_handle);
    }
    _status = MPVPlayerStatusUnknown;
    [NSNotificationCenter.defaultCenter postNotificationName:MPVPlayerWillShutdownNotification object:self userInfo:nil];
    [_observed removeAllObjects];
    
    mpv_terminate_destroy(_mpv_handle);
    _mpv_handle = NULL;
}

- (void)notifyObservers:(mpv_event_property *) event_property {
@autoreleasepool {
#ifdef DEBUG
    NSLog(@"Property did change: %s format: %i", event_property->name, event_property->format);
#endif
    
    id value = nil;
    switch (event_property->format) {
        case MPV_FORMAT_STRING:
        case MPV_FORMAT_OSD_STRING:
        {
            char *string = *(char **)(event_property->data);
            value = @(string);
        }
            break;
            
        case MPV_FORMAT_FLAG:
        case MPV_FORMAT_INT64:
        {
            int64_t val = *(int64_t *)(event_property->data);
            value = @(val);
        }
            break;
        case MPV_FORMAT_DOUBLE:
        {
            double val = *(double *)(event_property->data);
            value = @(val);
        }
            break;
            
        default:
            NSLog(@"%s Unsupported format: %i", __PRETTY_FUNCTION__, event_property->format);
            return;
            break;
    }
    
    NSString *property = @(event_property->name);
    NSPointerArray *observers = _observed[property];
    if (observers) {
        for (id <MPVPropertyObserving> observer in observers) {
            [observer player:self didChangeValue:value forProperty:property format:event_property->format];
        }
    }
}
}

#pragma mark - Properties

- (void)setSpeed:(double)speed {
    [self setDouble:speed forProperty:MPVPlayerPropertySpeed];
}

- (double)speed {
    return [self doubleForProperty:MPVPlayerPropertySpeed];
}

- (double)timePosition {
    double result = 0;
    int error = mpv_get_value_for_key(_mpv_handle, &result, "time-pos");
    if (error != MPV_ERROR_SUCCESS) {
        mpv_print_error_get_property(error, @"time-pos");
    }
    return result;
}

- (void)setTimePosition:(double)value {
    int error = mpv_set_value_for_key(_mpv_handle, value, "time-pos");
    if (error != MPV_ERROR_SUCCESS) {
        mpv_print_error_set_property(error, @"time-pos", "%g", value);
    }
}

- (double)percentPosition {
    return [self doubleForProperty:MPVPlayerPropertyPercentPosition];
}

- (void)setPercentPosition:(double)percentPosition {
    [self setDouble:percentPosition forProperty:MPVPlayerPropertyPercentPosition];
}

- (double)volume {
    return [self doubleForProperty:MPVPlayerPropertyVolume];
}

- (void)setVolume:(double)volume {
    [self setDouble:volume forProperty:MPVPlayerPropertyVolume];
}

- (BOOL)isMuted {
    return [self boolForProperty:MPVPlayerPropertyMute];
}

- (void)setMuted:(BOOL)muted {
    [self setBool:muted forProperty:MPVPlayerPropertyMute];
}

#pragma mark - Methods

- (void)quit {
    [self performCommand:MPVPlayerCommandQuit];
}

- (BOOL)takeScreenshotTo:(NSURL *)url includeSubtitles:(BOOL)flag error:(NSError *__autoreleasing  _Nullable *)error {
    
    mpv_node nodes[] = {
        { .u.string = "osd-msg",                               .format = MPV_FORMAT_STRING },
        { .u.string = "screenshot-to-file",                    .format = MPV_FORMAT_STRING },
        { .u.string = (char *)url.fileSystemRepresentation,    .format = MPV_FORMAT_STRING },
        { .u.string = (flag) ? "subtitles" : "video",          .format = MPV_FORMAT_STRING }
    };
    
    mpv_node_list array = {
        .num    = sizeof(nodes) / sizeof(mpv_node),
        .values = nodes,
        .keys   = NULL
    };
    
    mpv_node arg = {
        .u.list = &array,
        .format = MPV_FORMAT_NODE_ARRAY
    };
    
    int ret = mpv_command_node(_mpv_handle, &arg, NULL);
    
    if (ret != MPV_ERROR_SUCCESS) {
        if (error) {
            *error = [[NSError alloc]
                      initWithDomain:MPVPlayerErrorDomain
                      code:ret
                      userInfo:@{ NSLocalizedDescriptionKey : @( mpv_error_string(ret) ) }];
        }
        return NO;
    }
    
    return YES;
}

- (BOOL)takeScreenshotError:(NSError *__autoreleasing  _Nullable *)error {
    
    mpv_node nodes[] = {
        { .u.string = "osd-msg",        .format = MPV_FORMAT_STRING },
        { .u.string = "screenshot",     .format = MPV_FORMAT_STRING },
        { .u.string = "video",          .format = MPV_FORMAT_STRING }
    };
    
    mpv_node_list array = {
        .num    = sizeof(nodes) / sizeof(mpv_node),
        .values = nodes,
        .keys   = NULL
    };
    
    mpv_node arg = {
        .u.list = &array,
        .format = MPV_FORMAT_NODE_ARRAY
    };
    
    int ret = mpv_command_node(_mpv_handle, &arg, NULL);
    
    if (ret != MPV_ERROR_SUCCESS) {
        if (error) {
            *error = [[NSError alloc]
                      initWithDomain:MPVPlayerErrorDomain
                      code:ret
                      userInfo:@{ NSLocalizedDescriptionKey : @( mpv_error_string(ret) ) }];
        }
        return NO;
    }
    
    return YES;
}

- (void)printOSDMessage:(NSString *)text {
    [self printOSDMessage:text duration:3 level:0];
}

- (void)printOSDMessage:(NSString *)text duration:(double)seconds level:(int)osdLevel {
    
    mpv_node nodes[] = {
        
        { .u.string  = "show-text",                 .format = MPV_FORMAT_STRING },
        { .u.string  = (char *)text.UTF8String,     .format = MPV_FORMAT_STRING },
        { .u.int64   = seconds * NSEC_PER_USEC,     .format = MPV_FORMAT_INT64  },
        { .u.int64   = osdLevel,                    .format = MPV_FORMAT_INT64  },
        
    };
    
    mpv_node_list array = {
        .num    = sizeof(nodes) / sizeof(mpv_node),
        .values = nodes,
        .keys   = NULL
    };
    
    mpv_node arg = {
        .u.list = &array,
        .format = MPV_FORMAT_NODE_ARRAY
    };
    
    mpv_command_node(_mpv_handle, &arg, NULL);
}

- (void)openURL:(NSURL *)url {
    [self performCommand:MPVPlayerCommandLoadFile withArgument:url.absoluteString withArgument:nil];
    _url = url;
    _currentItem = nil;
}

- (MPVPlayerItem *)currentItem {
    return _currentItem;
}

- (void)setCurrentItem:(MPVPlayerItem *)currentItem {
    _url = nil;
    _currentItem = currentItem;
    if (currentItem) {
        [self performCommand:MPVPlayerCommandLoadFile withArgument:currentItem.url.absoluteString];
    } else {
        [self stop];
    }
}

- (void)play {
    [self setBool:NO forProperty:MPVPlayerPropertyPause];
}

- (void)pause {
    [self setBool:YES forProperty:MPVPlayerPropertyPause];
}

- (void)stop {
    [self performCommand:MPVPlayerCommandStop];
}

- (BOOL)isPaused {
    return [self boolForProperty:MPVPlayerPropertyPause];
}

- (void)seekTo:(double)time {
    
    mpv_node nodes[] = {
        
        { .u.string  = "seek",               .format = MPV_FORMAT_STRING },
        { .u.double_ = time,                 .format = MPV_FORMAT_DOUBLE },
        { .u.string  = "absolute+keyframes", .format = MPV_FORMAT_STRING }
        
    };
    
    mpv_node_list array = {
        .num    = 3,
        .values = nodes,
        .keys   = NULL
    };
    
    mpv_node arg = {
        .u.list = &array,
        .format = MPV_FORMAT_NODE_ARRAY
    };
    
    mpv_command_node_async(_mpv_handle, 1, &arg);
}

- (void)seekExactTo:(double)time {
    mpv_node nodes[] = {
        
        { .u.string  = "seek",              .format = MPV_FORMAT_STRING },
        { .u.double_ = time,                .format = MPV_FORMAT_DOUBLE },
        { .u.string  = "absolute+exact",    .format = MPV_FORMAT_STRING }
        
    };
    
    mpv_node_list array = {
        .num    = 3,
        .values = nodes,
        .keys   = NULL
    };
    
    mpv_node arg = {
        .u.list = &array,
        .format = MPV_FORMAT_NODE_ARRAY
    };
    
    mpv_command_node_async(_mpv_handle, 1, &arg);
}

- (void)setBool:(BOOL)value forProperty:(NSString *)property {
    int error = mpv_set_value_for_key(_mpv_handle, (int)value, property.UTF8String);
    if (error != MPV_ERROR_SUCCESS) {
        mpv_print_error_set_property(error, property, "%d", value);
    }
}

- (void)setString:(NSString *)value forProperty:(NSString *)property {
    int error = mpv_set_value_for_key(_mpv_handle, value.UTF8String, property.UTF8String);
    if (error != MPV_ERROR_SUCCESS) {
        mpv_print_error_set_property(error, property, "%@", value);
    }
}

- (void)setInteger:(NSInteger)value forProperty:(NSString *)property {
    int error = mpv_set_value_for_key(_mpv_handle, (int64_t)value, property.UTF8String);
    if (error != MPV_ERROR_SUCCESS) {
        mpv_print_error_set_property(error, property, "%ld", value);
    }
}

- (void)setDouble:(double)value forProperty:(NSString *)property {
    int error = mpv_set_value_for_key(_mpv_handle, value, property.UTF8String);
    if (error != MPV_ERROR_SUCCESS) {
        mpv_print_error_set_property(error, property, "%g", value);
    }
}

- (BOOL)setString:(NSString *)value forProperty:(NSString *)property error:(NSError * _Nullable __autoreleasing *)error {
    int result = mpv_set_value_for_key(_mpv_handle, value.UTF8String, property.UTF8String);
    if (result != MPV_ERROR_SUCCESS) {
        if (error) {
            NSString *description = [NSString stringWithFormat:@"Failed to set '%@=%@' option\n"
                                     "(%i) %s", property, value, result, mpv_error_string(result)];
            NSString *recoverySuggestion = @"Please, correct or remove it from the preferences";
            
            *error = [NSError errorWithDomain:MPVPlayerErrorDomain
                                         code:result
                                     userInfo:@{ NSLocalizedDescriptionKey              : description,
                                                 NSLocalizedRecoverySuggestionErrorKey  : recoverySuggestion }];
        } else {
            mpv_print_error_set_property(result, property, "%@", value);
        }
        return NO;
    }
    return YES;
}

- (BOOL)boolForProperty:(NSString *)property {
    int result = 0;
    int error = mpv_get_value_for_key(_mpv_handle, &result, property.UTF8String);
    if (error != MPV_ERROR_SUCCESS) {
        mpv_print_error_get_property(error, property);
    }
    return result;
}

- (NSString *)stringForProperty:(NSString *)property {
    char *result = NULL;
    int error = mpv_get_value_for_key(_mpv_handle, &result, property.UTF8String);
    if (result) {
        NSString *string = @(result);
        mpv_free(result);
        return string;
    } else {
        if (error != MPV_ERROR_SUCCESS) {
            mpv_print_error_get_property(error, property);
        }
    }
    
    return nil;
}

- (NSInteger)integerForProperty:(NSString *)property {
    int64_t result = 0;
    int error = mpv_get_value_for_key(_mpv_handle, &result, property.UTF8String);
    if (error != MPV_ERROR_SUCCESS) {
        mpv_print_error_get_property(error, property);
    }
    return result;
}

- (double)doubleForProperty:(NSString *)property {
    double result = 0;
    int error = mpv_get_value_for_key(_mpv_handle, &result, property.UTF8String);
    if (error != MPV_ERROR_SUCCESS) {
        mpv_print_error_get_property(error, property);
    }
    return result;
}

- (void)performCommand:(NSString *)command withArgument:(NSString *)arg1 withArgument:(NSString *)arg2 withArgument:(NSString *)arg3 {
    int error = mpv_perform_command_with_arguments(_mpv_handle, command.UTF8String, arg1.UTF8String, arg2.UTF8String, arg3.UTF8String);
    if (error != MPV_ERROR_SUCCESS) {
        mpv_print_error_generic(error, "Failed to perform command '%@' with arguments '%@', '%@', '%@'", command, arg1, arg2, arg3);
    }
}

- (void)performCommand:(NSString *)command withArgument:(NSString *)arg1 withArgument:(NSString *)arg2 {
    int error = mpv_perform_command_with_arguments(_mpv_handle, command.UTF8String, arg1.UTF8String, arg2.UTF8String);
    if (error != MPV_ERROR_SUCCESS) {
        mpv_print_error_generic(error, "Failed to perform command '%@' with arguments '%@', '%@'", command, arg1, arg2);
    }
}

- (void)performCommand:(NSString *)command withArgument:(NSString *)arg1 {
    int error = mpv_perform_command_with_argument(_mpv_handle, command.UTF8String, arg1.UTF8String);
    if (error != MPV_ERROR_SUCCESS) {
        mpv_print_error_generic(error, "Failed to perform command '%@' with argument '%@'", command, arg1);
    }
}

- (void)performCommand:(NSString *)command {
    int error = mpv_perform_command(_mpv_handle, command.UTF8String);
    if (error != MPV_ERROR_SUCCESS) {
        mpv_print_error_generic(error, "Failed to perform command '%@'", command);
    }
}

- (void)addObserver:(id<MPVPropertyObserving>)observer
        forProperty:(NSString *)property
             format:(mpv_format)format {
    NSPointerArray *observers = _observed[property];
    if (observers) {
        if (![observers containsObject:observer]) {
            [observers addObject:observer];
        }
    } else {
        observers = [NSPointerArray arrayWithObject:observer];
        int e = mpv_observe_property(_mpv_handle, (uint64_t)observers,
                                     property.UTF8String, format);
        if (e != MPV_ERROR_SUCCESS) {
            mpv_print_error_generic(e, @"Failed to add observer %@ for "
                                    "property: %@", observer, property);
            return;
        }
        _observed[property] = observers;
    }
#ifdef DEBUG
    NSLog(@"%llx: add observer: %@ property: %@ total: %lu", (uint64_t)observers, observer, property, observers.count);
#endif
}

- (void)removeObserver:(id<MPVPropertyObserving>)observer forProperty:(NSString *)property {
    
    if (property) { // remove observer for the specific property
        NSPointerArray *observers = _observed[property];
        [observers removeObject:observer];
#ifdef DEBUG
        NSLog(@"%llx: remove observer: %@ property: %@ total: %lu", (uint64_t)observers, observer, property, observers.count);
#endif
        if (observers.count == 0) {
            [_observed removeObjectForKey:property];
            int error =  mpv_unobserve_property(_mpv_handle, (uint64_t)observers);
            if (error < 0) {
                mpv_print_error_generic(error, @"Failed to remove observer %@ for property: %@", observer, property);
            } else {
                NSLog(@"%llx: stop observing property: %@", (uint64_t)observers, property);
            }
        }
    } else { // remove observer for all properties
        [_observed.copy enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            NSPointerArray *observers = obj;
            [observers removeObject:observer];
#ifdef DEBUG
            NSLog(@"%llx: remove observer: %@ property: %@ total: %lu", (uint64_t)observers, observer, key, observers.count);
#endif
            if (observers.count == 0) {
                [_observed removeObjectForKey:key];
                int error =  mpv_unobserve_property(_mpv_handle, (uint64_t)observers);
                if (error < 0) {
                    mpv_print_error_generic(error, @"Failed to remove observer %@ for property: %@", observer, key);
                } else {
                    NSLog(@"%llx: stop observing property: %@", (uint64_t)observers, key);
                }
            }
        }];
    }
}

@end

