//
//  SLTRemotePlayer.m
//  Slash
//
//  Created by Terminator on 2021/3/19.
//  Copyright © 2021年 digital-pers0n. All rights reserved.
//

#import "SLTRemotePlayer.h"
#import "SLTUtils.h"

#import "RemotePlayer.h"
#import "SPrint.h"

[[clang::objc_direct_members]]
@implementation SLTRemotePlayer {
    SL::RemotePlayer _player;
    Dispatch::Queue _playerQueue;
    NSMutableArray *_enqueuedCommands;
    NSString *_mpvPath;
    NSString *_mpvConfigPath;
    BOOL _fileLoaded;
    BOOL _isLegacyMPV;
    BOOL _shouldCheckMPV;
}

namespace {
    NSString *const SLTRemotePlayerDefaultPath = @"/usr/local/bin/mpv";
}

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken = 0;
    static SLTRemotePlayer *sharedInstance = nil;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SLTRemotePlayer alloc] initWithPath:nil
                                configurationFile:nil mediaFileURL:nil];
    });
    return sharedInstance;
}

//MARK:- Init

- (instancetype)initWithPath:(nullable NSString *)playerPath
           configurationFile:(nullable NSString *)configPath
                mediaFileURL:(nullable NSURL *)mediaURL
{
    if (!(self = [super init])) return nil;
    self.mpvPath = playerPath;
    _mpvConfigPath = configPath ? configPath.copy : nil;
    _url = mediaURL;
    _playerQueue = Dispatch::CreateSerialQueue("org.slash.remote-player.queue");
    _enqueuedCommands = [NSMutableArray new];
    return self;
}

- (instancetype)init {
    return [self initWithPath:nil configurationFile:nil mediaFileURL:nil];
}

//MARK:- Async methods

- (void)perform:(void(^)(const SL::RemotePlayer &player))task {
    const auto p = &_player;
    _playerQueue.async(^{ task(*p); });
}

- (void)performAndWait:(void(^)(const SL::RemotePlayer &player))task {
    const auto p = &_player;
    _playerQueue.sync(^{ task(*p); });
}

- (void)performIf:(BOOL)cond handler:(void(^)(const SL::RemotePlayer &))task {
    if (cond) {
        [self perform:task];
        return;
    }
    [_enqueuedCommands addObject:[task copy]];
}

- (void)performIfFileLoaded:(void(^)(const SL::RemotePlayer &player))task {
    [self performIf:_fileLoaded handler:task];
}

//MARK:- Properties

- (void)setUrl:(NSURL *)url {
    _url = url;
    _fileLoaded = NO;
    [self loadFile];
}

- (void)setMpvPath:(NSString *)mpvPath {
    _mpvPath = mpvPath ? mpvPath.copy : SLTRemotePlayerDefaultPath;
    _shouldCheckMPV = YES;
}

//MARK:- Commands

- (void)setMpvPathAndReload:(NSString *)path {
    self.mpvPath = path;
    [self reload];
}

- (void)reload {
    const BOOL shouldRelaunch = _fileLoaded;
    [self quit];
    if (shouldRelaunch && _url) [self launch];
}

- (void)loadFile:(NSURL *)url {
    [self perform:^(const SL::RemotePlayer &player) {
        player.loadFile(url.absoluteString.UTF8String);
    }];
}

- (void)loadFile {
    if (_url) {
        if (_player.isValid()) {
            [self loadFile:_url];
        } else {
            [self launch];
        }
    }
}

- (void)quit {
    if (_player.isValid()) {
        [self performAndWait:^(const SL::RemotePlayer &player) {
            player.quit();
        }];
    }
}

- (void)invalidate {
    _player.invalidate();
    _fileLoaded = NO;
}

- (void)play {
    if (!_fileLoaded) {
        [self loadFile];
    }
    
    [self performIfFileLoaded:^(const SL::RemotePlayer &player) {
        player.play();
    }];
}

- (void)seekTo:(double)seconds {
    [self performIfFileLoaded:^(const SL::RemotePlayer &player) {
        player.seekTo(seconds);
    }];
}

- (void)sendCommand:(NSString *)mpvCommand {
    [self performIfFileLoaded:^(const SL::RemotePlayer &player) {
       player.sendCommand(mpvCommand.UTF8String);
    }];
}

- (void)setProperty:(NSString *)string {
    [self performIfFileLoaded:^(const SL::RemotePlayer &player) {
        player.setProperty(string.UTF8String);
    }];
}

- (void)orderFront {
    [self perform:^(const SL::RemotePlayer &player) {
        const char *errMsg = __PRETTY_FUNCTION__;
        const auto fn = [&](const char *cmd) {
            player.sendMessage(cmd, strlen(cmd), errMsg);
        };
        fn("{ \"command\": [ \"set_property\", \"ontop\", \"yes\" ] }\n");
        fn("{ \"command\": [ \"set_property\", \"ontop\", \"no\" ] }\n");
    }];
}

- (void)setVideoFilter:(NSString *)string {
    [self perform:^(const SL::RemotePlayer &player) {
        player.setVideoFilter(string.UTF8String);
    }];
}

- (void)launch {
    __unsafe_unretained auto u = self;
    
    auto socketPath = [SLTTemporaryDirectory() stringByAppendingPathComponent:
                       SL::SPrint("mpv_%.4x", arc4random_uniform(10000))];
    
    const char *args[] = {
        _mpvPath.UTF8String, "--keep-open", "--idle",
        _mpvConfigPath ? "--include" : NULL, _mpvConfigPath.UTF8String, NULL
    };
    
    const auto isLegacyMPV = [&] {
        if (_shouldCheckMPV) {
            _isLegacyMPV = SL::RemotePlayer::IsLegacyMPV(_mpvPath.UTF8String);
            _shouldCheckMPV = NO;
        }
        return bool(_isLegacyMPV);
    }();
    
    _player = SL::RemotePlayer { args, _playerQueue, socketPath.UTF8String,
        isLegacyMPV, /*attempts*/ 3,
        [&](const SL::RemotePlayer player) { // didConnect; current thread
            _error = nil;
            // Disable all events except 'file-loaded'
            [self perform:^(const SL::RemotePlayer &p) {
                const auto fn = [&](const char *m) {
                    p.sendMessage(m, strlen(m), "-[SLTRemotePlayer launch]");
                };
                fn("{ \"command\": [ \"disable_event\", \"all\" ] }\n");
                fn("{ \"command\": [ \"enable_event\", \"file-loaded\" ] }\n");
            }];
            if (_url) {
                [self loadFile:_url];
            }
        },
        [](const char *outLog, size_t len) { // stdout
#if DEBUG
            write(STDOUT_FILENO, outLog, len);
#endif
        },
        [](const char *errLog, size_t len) { // stderr
#if DEBUG
           write(STDERR_FILENO, errLog, len);
#endif
        },
        [=](const char *msg, size_t len) { // did receive a remote message
            const char *event = "file-loaded";
            if (memmem(msg, len, event, strlen(event))) {
                Dispatch::MainQueue().async(^{
                    using Fn = void(^)(const SL::RemotePlayer&);
                    u->_fileLoaded = YES;
                    for (Fn task in u->_enqueuedCommands) {
                        [u perform:task];
                    }
                    [u->_enqueuedCommands removeAllObjects];
                });
            }
#if DEBUG
            write(STDOUT_FILENO, msg, len);
#endif
        },
        [=] { // didDisconnect
            auto fm = [NSFileManager defaultManager];
            if (NSError *e; ![fm removeItemAtPath:socketPath error:&e]) {
                NSLog(@"-[SLTRemotePlayer launch] %@", e);
            }
            Dispatch::MainQueue().async(^{
                [u invalidate];
            });
        },
        [&](int errorCode) { // didFail; current thread
            _error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                         code:errorCode userInfo:nil];
            NSLog(@"-[SLTRemotePlayer launch] %@", _error);
        }}; // SL::RemotePlayer()
} // -launch

@end
