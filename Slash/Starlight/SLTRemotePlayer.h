//
//  SLTRemotePlayer.h
//  Slash
//
//  Created by Terminator on 2021/3/19.
//  Copyright © 2021年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLTRemotePlayer : NSObject

+ (instancetype)sharedInstance;

/**
 Create an instance.
 @param playerPath A valid path to mpv executable file,
                   if nil passed will try to execute /usr/local/bin/mpv
 @param configPath A valid path to a user-defined mpv configuration file
 @param mediaURL A valid url to a media file.
 */
- (instancetype)initWithPath:(nullable NSString *)playerPath
           configurationFile:(nullable NSString *)configPath
                mediaFileURL:(nullable NSURL *)mediaURL;

/**
 Modify the current path of mpv executable file.
 This method doesn't relaunch the player if it's currently running,
 use @c -reload method in order to relaunch the current instance.
 */
@property (nonatomic, null_resettable, copy) NSString *mpvPath;

/**
 Modify the current path of a user-defined mpv configuration file.
 If the player is currently running use @c -reload method to apply changes.
 */
@property (nonatomic, nullable, copy) NSString *mpvConfigPath;

/**
 Modify the media url. When set to a non-nil value and the player is not running 
 this method will try to launch it.
 */
@property (nonatomic, nullable) NSURL *url;

/** Indicate that mpv cannot be launched. */
@property (nonatomic, nullable, readonly) NSError *error;

/** Relaunch the current player if it's running. */
- (void)reload;
/** 
 Same as 
 @code
  player.mpvPath = aNewMpvPath;
  [player reload];
 @endcode
 */
- (void)setMpvPathAndReload:(NSString *)path;

/**
 Start/resume playback. If @c url property is not nil and the player is not 
 running this method will try to launch it.
 */
- (void)play;

/** Seek to specified position in seconds */
- (void)seekTo:(double)seconds;

/** Set a video filter. Pass @"" to clear it out. */
- (void)setVideoFilter:(NSString *)string;

/** 
 Set mpv property. Use mpv manual to find the list of valid properties.
 Property syntax @"\"property_name\", \"arg\"" e.g. @"\"fullscreen", \"yes\""
 */
- (void)setProperty:(NSString *)string;

/** Bring the player window in front of other windows. */
- (void)orderFront;

/** Quit the player. */
- (void)quit;

/** 
 Send mpv command. Use mpv manual to find the list of valid commands. 
 Command syntax @c @"\"command_name\", \"arg1\", \"arg2\", \"etc\""
 */
- (void)sendCommand:(NSString *)mpvCommand;

@end

NS_ASSUME_NONNULL_END
