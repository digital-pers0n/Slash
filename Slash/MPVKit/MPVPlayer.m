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

NSString * const MPVPlayerErrorDomain = @"com.home.mpvPlayer.ErrorDomain";


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

@interface MPVPlayer () {
    MPVPlayerItem *_currentItem;
}

@property NSThread *eventThread;
@property NSNotificationCenter *notificationCenter;

/// Observed Properties
@property NSMutableDictionary *observed;

@end

@implementation MPVPlayer

- (instancetype)initWithOptions:(NSDictionary<NSString *,NSString *> *)options {
    self = [super init];
    if (self) {
        __weak id ref = self;
        int error = [self setUpUsingBlock:^{
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
        __weak id ref = self;
        int error = [self setUpUsingBlock:^{
            int error = [ref loadConfig:path];
            if (error != MPV_ERROR_SUCCESS) {
                NSLog(@"Loading default options.");
                [ref loadDefaultOptions];
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
        __weak id ref = self;
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
    _eventThread.qualityOfService = QOS_CLASS_UTILITY;
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
    _notificationCenter = [NSNotificationCenter defaultCenter];
    [self startEventListener];
}


- (void)dealloc
{
    if (_status == MPVPlayerStatusReadyToPlay) {
        [self shutdown];
    }
}

- (void)readEvents {
    
    NSString *notification = nil;
    SEL postNotification = @selector(postNotification:);
    
    while (!_eventThread.cancelled) {
        mpv_event *event = mpv_wait_event(self->_mpv_handle, -1);
        switch (event->event_id) {
                
            case MPV_EVENT_NONE:
                goto exit;
                
            case MPV_EVENT_SHUTDOWN:
            {
                if (self->_status == MPVPlayerStatusReadyToPlay) {
                    [self performSelectorOnMainThread:@selector(shutdown) withObject:nil waitUntilDone:NO];
                }
            }
                goto exit;
                
            case MPV_EVENT_LOG_MESSAGE:
                mpv_print_log_message(event->data);
                break;
                
            case MPV_EVENT_START_FILE:
                notification = MPVPlayerWillStartPlaybackNotification;
                break;
                
            case MPV_EVENT_END_FILE:
                notification = MPVPlayerDidEndPlaybackNotification;
                break;
                
            case MPV_EVENT_FILE_LOADED:
                notification = MPVPlayerDidLoadFileNotification;
                break;
                
            case MPV_EVENT_IDLE:
                notification = MPVPlayerDidEnterIdleModeNotification;
                break;
                
            case MPV_EVENT_VIDEO_RECONFIG:
                notification = MPVPlayerVideoDidChangeNotification;
                break;
                
            case MPV_EVENT_SEEK:
                notification = MPVPlayerDidStartSeekNotification;
                break;
                
            case MPV_EVENT_PLAYBACK_RESTART:
                notification = MPVPlayerDidRestartPlaybackNotification;
                break;
                
            case MPV_EVENT_PROPERTY_CHANGE:
                [self notifyObservers:event->data];
                break;
                
            default:
                printf("event: %s\n", mpv_event_name(event->event_id));
                break;
        }
        
        if (notification) {
#ifdef DEBUG
            NSLog(@"%@: Post '%@' notification.", self, notification);
#endif
            [self performSelectorOnMainThread:postNotification withObject:notification waitUntilDone:NO];
            
            notification = nil;
        }
        
    }
    
exit:
#ifdef DEBUG
    NSLog(@"%@: Exit event thread", self);
#endif
    [NSThread exit];
}

- (void)shutdown {
    [_eventThread cancel];
    _status = MPVPlayerStatusUnknown;
    [self performCommand:@"quit"];
    [NSNotificationCenter.defaultCenter postNotificationName:MPVPlayerWillShutdownNotification object:self userInfo:nil];
    [_observed removeAllObjects];
    
    mpv_terminate_destroy(_mpv_handle);
    _mpv_handle = NULL;
}

- (void)postNotification:(NSString *)notification {
    [_notificationCenter postNotificationName:notification object:self userInfo:nil];
}

- (void)notifyObservers:(mpv_event_property *) event_property {
    
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
    NSArray *observers = _observed[property];
    if (observers) {
        for (id <MPVPropertyObserving> observer in observers) {
            [observer player:self didChangeValue:value forProperty:property format:event_property->format];
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
    return [self doubleForProperty:MPVPlayerPropertyTimePosition];
}

- (void)setTimePosition:(double)currentTimePosition {
    [self setDouble:currentTimePosition forProperty:MPVPlayerPropertyTimePosition];
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

- (void)seekTo:(double)time {
    mpv_command_async( _mpv_handle, 1, (const char * []) { "seek", [NSString stringWithFormat:@"%.3f", time].UTF8String, "absolute+keyframes", NULL } );
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
    
    NSMutableArray *observers = _observed[property];
    if (observers) {
        if (![observers containsObject:observer]) {
            [observers addObject:observer];
        }
    } else {
        observers = [NSMutableArray arrayWithObject:observer];
        _observed[property] = observers;
        mpv_observe_property(_mpv_handle, (uint64_t)observers, property.UTF8String, format);
    }
#ifdef DEBUG
    NSLog(@"%llx: add observer: %@ property: %@ total: %lu", (uint64_t)observers, observer, property, observers.count);
#endif
}

- (void)removeObserver:(id<MPVPropertyObserving>)observer forProperty:(NSString *)property {
    
    if (property) { // remove observer for the specific property
        NSMutableArray *observers = _observed[property];
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
            NSMutableArray *observers = obj;
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

