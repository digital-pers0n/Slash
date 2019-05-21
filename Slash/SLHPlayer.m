//
//  SLHPlayer.m
//  Slash
//
//  Created by Terminator on 2018/08/14.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import "SLHPlayer.h"
#import "SLHMediaItem.h"
#import "SLHPreferences.h"
#import "slh_mpv.h"

@interface SLHPlayer () {
    Player *_player;
    BOOL _fileLoaded;
    dispatch_queue_t _main_thread;
}

@property BOOL fileLoaded;
@property BOOL hasWindow;

@end

@implementation SLHPlayer

#pragma mark - Initialization

+ (instancetype)playerWithPath:(NSString *)path {
    return [[SLHPlayer alloc] initWithMediaItem:[SLHMediaItem mediaItemWithPath:path]];
}

+ (instancetype)playerWithMediaItem:(SLHMediaItem *)item {
    return [[SLHPlayer alloc] initWithMediaItem:item];
}

- (instancetype)init {
    return [self initWithMediaItem:nil];
}

- (instancetype)initWithPath:(NSString *)path {
    return [self initWithMediaItem:[SLHMediaItem mediaItemWithPath:path]];
}

- (instancetype)initWithMediaItem:(SLHMediaItem *)item {
    self = [super init];
    if (self) {
        _currentItem = item;
        if (_currentItem) {
            if (_currentItem.status == SLHMediaItemStatusFailed) {
                _status = SLHPlayerStatusFailed;
                _error = _currentItem.error;
            }
        } else {
            _status = SLHPlayerStatusUnknown;
        }
        [self _setUpPlayer];

    }
    return self;
}

- (void)_setUpPlayer {
    _player = malloc(sizeof(Player));
    NSString *mpvPath = [[NSUserDefaults standardUserDefaults] objectForKey:SLHPreferencesMPVFilePathKey];
    if (!mpvPath) { // use default path
        mpvPath = @"/usr/local/bin/mpv";
    }
    SLHPreferences *prefs = [SLHPreferences preferences];
    NSString *confPath = prefs.mpvConfigPath;
    NSString *scriptPath = prefs.mpvLuaScriptPath;
    const char *args[] = {mpvPath.UTF8String, "--include", confPath.UTF8String, "--script", scriptPath.UTF8String, NULL};
    if (plr_init(_player, (char *const *)args) != 0) {
        _status = SLHPlayerStatusFailed;
        _error = [[NSError alloc] initWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{ NSLocalizedDescriptionKey: @"Initialization Failed"}];
        return;
    }
    plr_set_callback(_player, (__bridge void *)(self), _mpv_callback);
    plr_set_exit_cb(_player, _mpv_exit_cb);
    
    plr_launch(_player);
    sleep(1);
    plr_connect(_player);
    _fileLoaded = NO;
    _hasWindow = YES;
    _main_thread = dispatch_get_main_queue();
}

static inline bool _isScript(const char *str) {
    return (str[0] == '[' && str[1] == 's' && str[2] == 'c') ? YES : NO;
}

static void _mpv_callback(char *str, void *ctx) {
    if (_isScript(str)) {
        SLHPlayer *p = (__bridge SLHPlayer *)(ctx);
        switch (str[9]) {
            case 'A': // [script] A:
            {
                //puts(str + 11);
                double val = strtod(str + 11, 0);
                dispatch_async(p->_main_thread, ^{
                    [p.delegate player:p segmentStart:val];
                });
            }
                
                break;
            case 'B': // [script] B:
            {
                //puts(str + 11);
                double val = strtod(str + 11, 0);
                dispatch_async(p->_main_thread, ^{
                    [p.delegate player:p segmentEnd:val];
                });
                
            }
                break;
            case '+': // [script] +
            {
                //puts(str + 9);
                dispatch_async(p->_main_thread, ^{
                    [p.delegate playerDidEndEditingSegment:p];
                });
            }
                break;
                
            case '-': // [script] -
            {
                 //puts(str + 9);
                dispatch_async(p->_main_thread, ^{
                    [p.delegate playerDidClearSegment:p];
                });
            }
                break;
                
            default:
                break;
        }
    }
}

static void _mpv_exit_cb(void *p, void *ctx) {
    SLHPlayer *player = (__bridge SLHPlayer *)(ctx);
    player.hasWindow = NO;
}

-(void)dealloc {
    plr_destroy(_player);
    free(_player);
}

#pragma mark - Methods

static inline void _loadFile(Player *p, const char *path) {
    char *cmd;
    asprintf(&cmd, "{ \"command\": [\"loadfile\", \"%s\"] }\n", path);
    plr_msg_send(p, cmd);
    free(cmd);
}

static inline void _launchPlayer(Player *p) {
    plr_launch(p);
    sleep(1);
    plr_connect(p);
}

- (void)play {
    if (!_hasWindow) {
        _launchPlayer(_player);
        _fileLoaded = NO;
        _hasWindow = YES;
    }
    if (!_fileLoaded) {
        _fileLoaded = YES;
        _loadFile(_player, _currentItem.filePath.UTF8String);
    }
    char *cmd = "{ \"command\": [\"set_property\", \"pause\", \"no\"] }\n";
    plr_msg_send(_player, cmd);
}

- (void)pause {
    char *cmd = "{ \"command\": [\"set_property\", \"pause\", \"yes\"] }\n";
    plr_msg_send(_player, cmd);
}

- (void)replaceCurrentItemWithMediaItem:(SLHMediaItem *) item {
    if (!_hasWindow) {
        _launchPlayer(_player);
        _hasWindow = YES;
    }
    _currentItem = item;
    _loadFile(_player, _currentItem.filePath.UTF8String);
}

- (double)currentTime {
    return 0;
}

- (void)seekToTime:(double)time {
    char *pos;
    asprintf(&pos,  "{ \"command\": [\"set_property\", \"time-pos\", \"%f\" ] }\n", time);
    plr_msg_send(_player, pos);
    free(pos);
}

- (void)loopStart:(double)a end:(double)b {
    char *start, *end, *pos;
    asprintf(&start,  "{ \"command\": [\"set_property\", \"ab-loop-a\", \"%f\" ] }\n", a);
    asprintf(&end,  "{ \"command\": [\"set_property\", \"ab-loop-b\", \"%f\" ] }\n", b);
    asprintf(&pos,  "{ \"command\": [\"set_property\", \"time-pos\", \"%f\" ] }\n", a);
    plr_msg_send(_player, pos);
    plr_msg_send(_player, start);
    plr_msg_send(_player, end);
    
    free(start);
    free(end);
    free(pos);
}

@end
