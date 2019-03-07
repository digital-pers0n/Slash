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

extern NSString *const SLHPlayerMPVConfigPath;

@interface SLHPlayer () {
    Player *_player;
}
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
    
    NSString *confPath = [SLHPlayerMPVConfigPath stringByExpandingTildeInPath];
    const char *args[] = {mpvPath.UTF8String, confPath.UTF8String};
    if (plr_init(_player, (char *const *)args) != 0) {
        _status = SLHPlayerStatusFailed;
        _error = [[NSError alloc] initWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{ NSLocalizedDescriptionKey: @"Initialization Failed"}];
        return;
    }
    plr_set_callback(_player, (__bridge void *)(self), _mpv_callback);
}

static void _mpv_callback(char *str, void *ctx) {
    
}

-(void)dealloc {
    plr_destroy(_player);
    free(_player);
}

@end
