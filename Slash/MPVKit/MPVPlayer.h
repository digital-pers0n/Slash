//
//  MPVPlayer.h
//  Slash
//
//  Created by Terminator on 2019/10/12.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <mpv/client.h>

typedef NS_ENUM(NSInteger, MPVPlayerStatus) {
    MPVPlayerStatusUnknown,
    MPVPlayerStatusReadyToPlay,
    MPVPlayerStatusFailed
};

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString * const MPVPlayerErrorDomain;

@protocol MPVPropertyObserving;
@class MPVPlayerItem;

@interface MPVPlayer : NSObject

/** 
 Initialize the player using a user-defined block.
 The @c block will be called before the mpv_handle is initialized.
 Can be used to tweak mpv options that will become inaccessble after initialization is over.
 */
- (instancetype)initWithBlock:(void (^)(__weak MPVPlayer *p))block;

- (instancetype)initWithOptions:(NSDictionary <NSString *, NSString *> *)options;

/**
 @param path Must be an absolute file path. If @p path cannot be loaded, the default options are loaded instead.
 */
- (instancetype)initWithConfig:(NSString *)path;

@property (nonatomic, readonly, nullable) mpv_handle *mpv_handle;
@property (readonly, nullable) NSError *error;
@property (nonatomic, readonly) MPVPlayerStatus status;

- (void)openURL:(NSURL *)url;


/** 
 * @return the url that was passed to @c openURL: method previously, otherwise nil.
 */
@property (nonatomic, readonly, nullable) NSURL *url;

/**
 * @brief Get or set the player's current item
 * @discussion Use this method for media files that can be represented as MPVPlayerItem class objects
 * e.g. any supported media files that are not playlists or links to video streaming sites.
 */
@property (nonatomic, nullable) MPVPlayerItem *currentItem;

#pragma mark - Playback Control

- (void)play;
- (void)pause;
- (void)stop;
- (BOOL)isPaused;

@property (nonatomic) double speed;
@property (nonatomic) double timePosition;
@property (nonatomic) double percentPosition;
@property (nonatomic) double volume;
@property (nonatomic, getter=isMuted) BOOL muted;

/** async keyframe seek, faster than @c seekExactTo: method, but unprecise. */
- (void)seekTo:(double)time;

/** async exact seek, slower than @c seekTo: method, but much more precise. */
- (void)seekExactTo:(double)time;

/** Quit the player. */
- (void)quit;

#pragma mark - Properties

- (void)setBool:(BOOL)value forProperty:(NSString *)property;
- (void)setString:(NSString *)value forProperty:(NSString *)property;
- (void)setInteger:(NSInteger)value forProperty:(NSString *)property;
- (void)setDouble:(double)value forProperty:(NSString *)property;

- (BOOL)boolForProperty:(NSString *)property;
- (nullable NSString *)stringForProperty:(NSString *)property;
- (NSInteger)integerForProperty:(NSString *)property;
- (double)doubleForProperty:(NSString *)property;

- (BOOL)setString:(NSString *)value forProperty:(NSString *)property error:(NSError **)error;

#pragma mark - Commands

- (void)performCommand:(NSString *)command withArgument:(nullable NSString *)arg1 withArgument:(nullable NSString *)arg2 withArgument:(nullable NSString *)arg3;
- (void)performCommand:(NSString *)command withArgument:(nullable NSString *)arg1 withArgument:(nullable NSString *)arg2;
- (void)performCommand:(NSString *)command withArgument:(nullable NSString *)arg1;
- (void)performCommand:(NSString *)command;

#pragma mark - OSD

/** 
 Print a message to the OSD.
 */
- (void)printOSDMessage:(NSString *)text duration:(double)seconds level:(int)osdLevel;

/**
 Same as @c printOSDMessage:duration:level with 3 seconds duration and osd level 0
 */
- (void)printOSDMessage:(NSString *)text;

#pragma mark - Screenshot

/** 
 Take a screenshot.
 @param screenshotURL A full path where to write the screenshot. The screenshot format is guessed from the file extenstion.
 @param error A pointer to an NSError object. On return, identifies errors and other problems.
 @param includeSubs @c YES to take the screenshot with subtitles, @c NO to ignore them.
 @return YES if the screenshot is saved successfully, or NO if an error occurs.
 */
- (BOOL)takeScreenshotTo:(NSURL *)screenshotURL includeSubtitles:(BOOL)includeSubs error:(NSError * _Nullable *)error;

/**
 Take a screenshot. 
 An output filename is constructed using values of the @c --screenshot-format
 @c --screenshot-template and @c --screenshot-directory options.
 @param error A pointer to an NSError object. On return, identifies errors and other problems.
 @return YES if the screenshot is saved successfully, or NO if an error occurs.
 */
- (BOOL)takeScreenshotError:(NSError * _Nullable *)error;

#pragma mark - Add/Remove Property Observers

/**
 @param format supported formats are
 MPV_FORMAT_STRING, MPV_FORMAT_OSD_STRING, MPV_FORMAT_FLAG, MPV_FORMAT_INT64 and MPV_FORMAT_DOUBLE.
 */
- (void)addObserver:(id <MPVPropertyObserving>)observer forProperty:(NSString *)property format:(mpv_format)format;
- (void)removeObserver:(id <MPVPropertyObserving>)observer forProperty:(nullable NSString *)property;

@end

#pragma mark - Property Observing

@protocol MPVPropertyObserving <NSObject>

/**
 @discussion
 This method will be called from a background thread.
 @param value depended on a @p format argument. It can be an NSString object for MPV_FORMAT_STRING and MPV_FORMAT_OSD_STRING
              or an NSNumber object for MPV_FORMAT_FLAG, MPV_FORMAT_INT64 and MPV_FORMAT_DOUBLE formats.
 */
- (void)player:(MPVPlayer *)player didChangeValue:(id)value forProperty:(NSString *)property format:(mpv_format)format;

@end

#pragma mark - Notifications

/** MPV_EVENT_SHUTDOWN */
extern NSString * const MPVPlayerWillShutdownNotification;

/** MPV_EVENT_START_FILE */
extern NSString * const MPVPlayerWillStartPlaybackNotification;

/** MPV_EVENT_END_FILE */
extern NSString * const MPVPlayerDidEndPlaybackNotification;

/** MPV_EVENT_FILE_LOADED  */
extern NSString * const MPVPlayerDidLoadFileNotification;

/** MPV_EVENT_IDLE */
extern NSString * const MPVPlayerDidEnterIdleModeNotification;

/** MPV_EVENT_VIDEO_RECONFIG */
extern NSString * const MPVPlayerVideoDidChangeNotification;

/** MPV_EVENT_SEEK */
extern NSString * const MPVPlayerDidStartSeekNotification;

/** MPV_EVENT_PLAYBACK_RESTART */
extern NSString * const MPVPlayerDidRestartPlaybackNotification;

NS_ASSUME_NONNULL_END

