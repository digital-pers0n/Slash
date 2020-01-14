//
//  SLHExternalPlayer.m
//  Slash
//
//  Created by Terminator on 2019/12/11.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "slh_list.h"
#import "SLHExternalPlayer.h"
#import "slh_mpv.h"


static NSURL * defaultPlayerURL;
static NSURL * defaultPlayerConfigURL;

typedef Player * PlayerRef;

@interface SLHExternalPlayer () {
    Player _player;
    PlayerRef _playerRef;
    BOOL _fileLoaded;
    BOOL _hasWindow;
    dispatch_queue_t _queue;
    
    NSThread *_playerThread;
    
    Queue _commandQueue;
}

@end

@implementation SLHExternalPlayer

#pragma mark - Initialization

+ (void)initialize {
    if (self == [SLHExternalPlayer class]) {
        defaultPlayerURL = [NSURL fileURLWithPath:@"/usr/local/bin/mpv"];
    }
}

+ (NSURL *)defaultPlayerURL {
    return defaultPlayerURL;
}

+ (void)setDefaultPlayerURL:(NSURL *)url {
    defaultPlayerURL = url;
}

+ (NSURL *)defaultPlayerConfigURL {
    return defaultPlayerConfigURL;
}

+ (void)setDefaultPlayerConfigURL:(NSURL *)url {
    defaultPlayerConfigURL = url;
}

+ (instancetype)defaultPlayer {
    static dispatch_once_t onceToken;
    static SLHExternalPlayer *player;
    dispatch_once(&onceToken, ^{
        player = [[SLHExternalPlayer alloc] init];
    });
    return player;
}

+ (instancetype)playerWithURL:(NSURL *)url configurationFile:(NSURL *)config mediaFileURL:(NSURL *)mediaURL {
    return [[SLHExternalPlayer alloc] initWithURL:url configurationFile:config mediaFileURL:mediaURL];
}

+ (instancetype)playerWithMediaURL:(NSURL *)mediaURL {
    return [[SLHExternalPlayer alloc] initWithURL:defaultPlayerURL configurationFile:defaultPlayerConfigURL mediaFileURL:mediaURL];
}

- (instancetype)initWithURL:(NSURL *)url configurationFile:(NSURL *)config mediaFileURL:(NSURL *)mediaURL {
    self = [super init];
    if (self) {
        queue_init(&_commandQueue, &free);
        _queue = dispatch_get_main_queue();
        if (!url) {
            if (defaultPlayerURL) {
                url = defaultPlayerURL;
            } else {
                NSString *errorDescription = [NSString stringWithFormat:@"Cannot find mpv binary."];
                _error = [[NSError alloc] initWithDomain:NSPOSIXErrorDomain
                                                    code:ENOENT
                                                userInfo:@{NSLocalizedDescriptionKey : errorDescription }];
                return self;
            }
        }
        
        if (!config) {
            config = defaultPlayerConfigURL;
        }
        
        const char * const args[] = {
            url.path.UTF8String,
            "--keep-open",
            "--idle",
            (config) ? "--include" : NULL,
            config.fileSystemRepresentation, NULL };
        
        PlayerRef player = &_player;
        if (plr_init(player, (char *const *)args) != 0) {
           _error = [[NSError alloc] initWithDomain:NSPOSIXErrorDomain
                                               code:EINVAL
                                           userInfo:@{ NSLocalizedDescriptionKey: @"Cannot initialize." }];
            return self;
        }
        _playerRef = player;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
        
        plr_set_callback(player, (__bridge void *)self, &mpv_callback);
        plr_set_exit_cb(player, &mpv_exit_callback);
        
        if (player_relaunch(player) != 0) {
            _error = [[NSError alloc] initWithDomain:NSPOSIXErrorDomain
                                                code:errno
                                            userInfo:@{ NSLocalizedDescriptionKey: @(strerror(errno)) }];
            return self;
        }

        _url = mediaURL;
        _fileLoaded = NO;
        _hasWindow = YES;
        [self startEventThread];
    }
    return self;
}

- (instancetype)init {
    return [self initWithURL:defaultPlayerURL configurationFile:defaultPlayerConfigURL mediaFileURL:nil];
}

- (void)dealloc {
    [self cleanUp];
}

- (void)cleanUp {
    queue_destroy(&_commandQueue);
    if (_playerRef) {
        
        [_playerThread cancel];
        
        plr_destroy(_playerRef);
        _playerRef = NULL;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationWillTerminateNotification object:nil];
}

- (void)startEventThread {
    if (!_playerThread.executing) {
        [_playerThread cancel];
    }
    _playerThread = [[NSThread alloc] initWithTarget:self selector:@selector(playerMonitor:) object:nil];
    _playerThread.name = @"com.home.SLHExternalPlayer.player-monitor";
    _playerThread.qualityOfService = NSQualityOfServiceBackground;
    [_playerThread start];
}


#pragma mark - Properties

- (void)setUrl:(NSURL *)url {
    _url = url;
    if (url == nil) {
        [self quit];
    } else {
        __unsafe_unretained typeof(self) s = self;
        
        dispatch_async(_queue, ^{
            
            if (!s->_hasWindow) {
                if (player_relaunch(s->_playerRef) != 0) {
                    NSLog(@"%s Cannot launch mpv.", __PRETTY_FUNCTION__);
                    return;
                }
                s->_hasWindow = YES;
                
                [s startEventThread];
            }
            s->_fileLoaded = NO;
            player_load_file(s->_playerRef, s->_url.absoluteString.UTF8String);
            
        });
    }
}

#pragma mark - Playback Control

- (void)play {
     __unsafe_unretained typeof(self) s = self;
    
    dispatch_async(_queue, ^{
        
        if (!s->_hasWindow) {
            if (player_relaunch(s->_playerRef) != 0) {
                NSLog(@"%s Cannot launch mpv.", __PRETTY_FUNCTION__);
                return;
            }
            s->_fileLoaded = NO;
            s->_hasWindow = YES;
        }
        
        if (!s->_fileLoaded && s->_url) {
            player_load_file(s->_playerRef, s->_url.absoluteString.UTF8String);
        }
        
        const char cmd[] = "{ \"command\": [\"set_property\", \"pause\", \"no\"] }\n";
        plr_msg_send(s->_playerRef, cmd, sizeof(cmd) - 1);
        
    });
}

- (void)pause {
    __unsafe_unretained typeof(self) s = self;
    
    dispatch_async(_queue, ^{
        
        const char cmd[] = "{ \"command\": [\"set_property\", \"pause\", \"yes\"] }\n";
        plr_msg_send(s->_playerRef, cmd, sizeof(cmd) - 1);
        
    });
}

#pragma mark - Methods

- (void)quit {
    __unsafe_unretained typeof(self) s = self;
    
    dispatch_async(_queue, ^{
        
        const char cmd[] = "{ \"command\": [\"quit\"] }\n";
        plr_msg_send(s->_playerRef, cmd, sizeof(cmd) - 1);
        
    });
}

- (void)performCommand:(NSString *)args {
    if (!_fileLoaded) {
        queue_enqueue(&_commandQueue, strdup(args.UTF8String));
        return;
    }
    
    Player *player = _playerRef;
    dispatch_async(_queue, ^{
        player_send_command(player, args.UTF8String);
    });
    
}

- (void)setStayOnTop:(BOOL)value {
    
     __unsafe_unretained typeof(self) obj = self;
    
    dispatch_async(_queue, ^{
        size_t len = 0;
        const char *cmd = nil;
        if (value) {
            const char buf[] = "{ \"command\": [ \"set_property\", \"ontop\", \"yes\" ] }\n";
            len = sizeof(buf) - 1;
            cmd = buf;
        } else {
            const char buf[] = "{ \"command\": [ \"set_property\", \"ontop\", \"no\" ] }\n";
            len = sizeof(buf) - 1;
            cmd = buf;
        }
        plr_msg_send(obj->_playerRef, cmd, len);
    });
}

- (void)orderFront {
    [self setStayOnTop:YES];
    [self setStayOnTop:NO];
}

- (void)setVideoFilter:(NSString *)string {
    __unsafe_unretained typeof(self) obj = self;
    dispatch_async(_queue, ^{
        char *cmd = nil;
        size_t len = asprintf(&cmd, "{ \"command\": [ \"set_property\", \"vf\", \"%s\" ] }\n", string.UTF8String);
        plr_msg_send(obj->_playerRef, cmd, len);
        free(cmd);
    });
}

- (void)didLoadFile {
    _fileLoaded = YES;
     Player *player = _playerRef;
    while (queue_size(&_commandQueue) > 0) {
        void *data = nil;
        queue_dequeue(&_commandQueue, &data);
        dispatch_async(_queue, ^{
            player_send_command(player, data);
            free(data);
        });
    }
}

- (void)playerMonitor:(id)context {
    CFRunLoopRef rl = CFRunLoopGetMain();
    const size_t buffer_size = 256;
    char buffer[buffer_size + 1];
    while (_playerRef && !_playerThread.cancelled) {
        ssize_t len = plr_msg_recv(_playerRef, buffer, buffer_size);
        if (len > 0) {
            buffer[len] = '\0';
    
            if (strnstr(buffer, "file-loaded", len)) {
                 __unsafe_unretained typeof(self) obj = self;
                CFRunLoopPerformBlock(rl, kCFRunLoopCommonModes, ^{
                    [obj didLoadFile];
                });
            }

            fputs(buffer, stdout);
        } else {
            break;
        }
    }
    [NSThread exit];
}


#pragma mark - Notifications

- (void)applicationWillTerminate:(NSNotification *)n {
    [self cleanUp];
}

#pragma mark - Functions

static void player_send_command(Player *player, const char *args) {
    char *cmd = nil;
    size_t len = asprintf(&cmd, "{ \"command\": [%s] }\n", args);
    plr_msg_send(player, cmd, len);
    free(cmd);
}

static void player_load_file(Player *p, const char *path) {
    char *cmd;
    size_t len = asprintf(&cmd, "{ \"command\": [\"loadfile\", \"%s\"] }\n", path);
    plr_msg_send(p, cmd, len);
    free(cmd);
}

static int player_relaunch(Player *p) {
    int result;
    result = plr_launch(p);
    
    if (result != 0) {
        return result;
    }
    
    const struct timespec s = { .tv_sec = 1, .tv_nsec = 0 };
    nanosleep(&s, NULL);
    
    result = plr_connect(p);
    if (result != 0) {
        return result;
    }
    
    // Disable all events except "file-loaded"
    {
        const char cmd[] = "{ \"command\": [ \"disable_event\", \"all\" ] }\n";
        plr_msg_send(p, cmd, sizeof(cmd) - 1);
    }
    {
        const char cmd[] = "{ \"command\": [ \"enable_event\", \"file-loaded\" ] }\n";
        plr_msg_send(p, cmd, sizeof(cmd) - 1);
    }
    
    return result;
}

#pragma mark - Callbacks

static void mpv_callback(char *output, void *ctx) {
    //fputs(output, stdout);
}

static void mpv_exit_callback(void *player, void *ctx) {
    __unsafe_unretained SLHExternalPlayer * obj = (__bridge id)ctx;
    obj->_hasWindow = NO;
}

@end
