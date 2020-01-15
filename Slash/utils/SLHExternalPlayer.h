//
//  SLHExternalPlayer.h
//  Slash
//
//  Created by Terminator on 2019/12/11.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A simple mpv JSON IPC wrapper.
 */
@interface SLHExternalPlayer : NSObject

+ (nullable NSURL *)defaultPlayerURL;
+ (void)setDefaultPlayerURL:(nullable NSURL *)url;

+ (nullable NSURL *)defaultPlayerConfigURL;
+ (void)setDefaultPlayerConfigURL:(nullable NSURL *)url;

/**
 Shared player instance
 */
+ (instancetype)defaultPlayer;

/**
 Create an instance of SLHExternalPlayer.
 @param url A valid url to the mpv's binary. If nil, will try to load @c defaultPlayerURL
 @param config A valid url to a custom mpv.conf file or nil
 @param mediaURL A valid url to a media file or nil
 */
+ (instancetype)playerWithURL:(nullable NSURL *)url configurationFile:(nullable NSURL *)config mediaFileURL:(nullable NSURL *)mediaURL;;


/**
 Create an instance of SLHExternalPlayer with a given URL.
 @param mediaURL A valid url to a media file or nil.
 */
+ (instancetype)playerWithMediaURL:(nullable NSURL *)mediaURL;

/**
 Initialize an instance of SLHExternalPlayer.
 @param url A valid url to the mpv's binary. If nil, will try to load @c defaultPlayerURL.
 @param config A valid url to a custom mpv.conf file or nil
 @param mediaURL A valid url to a media file or nil
 */
- (instancetype)initWithURL:(nullable NSURL *)url configurationFile:(nullable NSURL *)config mediaFileURL:(nullable NSURL *)mediaURL NS_DESIGNATED_INITIALIZER;

/**
 Assign a media file url.
 */
@property (nullable, nonatomic) NSURL *url;

/**
 If not nil indicates why the player cannot be launched.
 */
@property (nullable, nonatomic, readonly) NSError *error;

- (void)play;
- (void)pause;
- (void)quit;

/**
 Seek to a given time in seconds
 */
- (void)seekTo:(double)seconds;

/**
 Set a video filter.
 */
- (void)setVideoFilter:(NSString *)string;

/**
 Make the player to stay on top of other windows.
 Can be useful for moving the player window back to the front if it is covered by other windows. 
 */
- (void)setStayOnTop:(BOOL)value;

/**
 Same as calling [player setStayOnTop:YES] and then [player setStayOnTop:NO]
 */
- (void)orderFront;

/**
 Send a remote command to the player.
 @note Command and arguments must be inside double quotes
 and separated by commas: @"\"command_name\", \"arg1\", \"arg2\", \"etc\""
 @param commandString A string that contains a name of a command and optional arguments.
*/
- (void)performCommand:(NSString *)commandString;

@end

NS_ASSUME_NONNULL_END
