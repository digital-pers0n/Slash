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


static NSURL * defaultPlayerURL = nil;
static NSURL * defaultPlayerConfigURL = nil;
static SLHExternalPlayer *defaultPlayerInstance = nil;
static dispatch_once_t defaultPlayerOnceToken;

typedef Player * PlayerRef;

@interface SLHExternalPlayer () {
    Player _player;
    PlayerRef _playerRef;
    BOOL _fileLoaded;
    BOOL _hasWindow;
    dispatch_queue_t _queue;
    
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
    dispatch_once(&defaultPlayerOnceToken, ^{
        defaultPlayerInstance = [[SLHExternalPlayer alloc] init];
    });
    return defaultPlayerInstance;
}

+ (void)reinitializeDefaultPlayer {
    NSURL *url = nil;
    if (defaultPlayerInstance) {
        if (defaultPlayerInstance.hasWindow) {
            url = defaultPlayerInstance.url;
        }
    }
    defaultPlayerOnceToken = 0;
    if (url) {
        SLHExternalPlayer *player = [SLHExternalPlayer defaultPlayer];
        player.url = url;
        [player play];
    }
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
        plr_set_ipc_cb(player, &mpv_ipc_callback);
        
        if (player_relaunch(player) != 0) {
            _error = [[NSError alloc] initWithDomain:NSPOSIXErrorDomain
                                                code:errno
                                            userInfo:@{ NSLocalizedDescriptionKey: @(strerror(errno)) }];
            return self;
        }

        _url = mediaURL;
        _fileLoaded = NO;
        _hasWindow = YES;
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
        plr_destroy(_playerRef);
        _playerRef = NULL;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationWillTerminateNotification object:nil];
}

#pragma mark - Properties

- (void)setUrl:(NSURL *)url {
    _url = url;
    _fileLoaded = NO;
    if (url == nil) {
        [self quit];
    } else {

        if (!_hasWindow) {
            if (player_relaunch(_playerRef) != 0) {
                NSLog(@"%s Cannot launch mpv.", __PRETTY_FUNCTION__);
                return;
            }
            _hasWindow = YES;
        }
        
        Player *player = _playerRef;
        
        dispatch_async(_queue, ^{
            player_load_file(player, url.absoluteString.UTF8String);
        });
    }
}

#pragma mark - Playback Control

- (void)play {
    
        if (!_fileLoaded && _url) {
            // try to load the file again
            self.url = _url;
        }
    
    Player *player = _playerRef;
    dispatch_async(_queue, ^{
        const char cmd[] = "{ \"command\": [\"set_property\", \"pause\", \"no\"] }\n";
        plr_msg_send(player, cmd, sizeof(cmd) - 1);
        
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

- (void)seekTo:(double)seconds {
    if (!_fileLoaded) {
        char *cmd = nil;
        asprintf(&cmd, "\"seek\", %f, \"absolute+exact\"", seconds);
        queue_enqueue(&_commandQueue, cmd);
        return;
    }
    
    Player *player = _playerRef;
    dispatch_async(_queue, ^{
       
        char *cmd = nil;
        size_t len = asprintf(&cmd, "{ \"command\": [ \"seek\", %f, \"absolute+exact\" ] }\n", seconds);
        plr_msg_send(player, cmd, len);
        free(cmd);
        
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

static void mpv_ipc_callback(ssize_t size, void *ctx) {
    
     __unsafe_unretained SLHExternalPlayer * obj = (__bridge id)ctx;
    char data[256];
    ssize_t nRead = 0;
    
    while (size > nRead) {
        nRead = plr_msg_recv(obj->_playerRef, data, sizeof(data) - 1);
    
        if (nRead > 0) {
            data[nRead] = '\0';
            
            if (strnstr(data, "file-loaded", nRead)) {
                CFRunLoopRef rl = CFRunLoopGetMain();
                CFRunLoopPerformBlock(rl, kCFRunLoopCommonModes, ^{
                    [obj didLoadFile];
                });
            }
#if DEBUG
            fputs(data, stdout);
#endif
        } else {
            break;
        }
    }
}

static void mpv_callback(char *output, void *ctx) {
    //fputs(output, stdout);
}

static void mpv_exit_callback(void *player, void *ctx) {
    __unsafe_unretained SLHExternalPlayer * obj = (__bridge id)ctx;
    obj->_hasWindow = NO;
}

@end
