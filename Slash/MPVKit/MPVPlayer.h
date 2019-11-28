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

@protocol MPVPropertyObserving;
@class MPVPlayerItem;

@interface MPVPlayer : NSObject

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

@property (nonatomic) double speed;
@property (nonatomic) double timePosition;
@property (nonatomic) double percentPosition;
@property (nonatomic) double volume;
@property (nonatomic, getter=isMuted) BOOL muted;

/** async keyframe seek, faster than @c seekExactTo: method, but unprecise. */
- (void)seekTo:(double)time;

- (void)shutdown;

#pragma mark - Properties

- (void)setBool:(BOOL)value forProperty:(NSString *)property;
- (void)setString:(NSString *)value forProperty:(NSString *)property;
- (void)setInteger:(NSInteger)value forProperty:(NSString *)property;
- (void)setDouble:(double)value forProperty:(NSString *)property;

- (BOOL)boolForProperty:(NSString *)property;
- (nullable NSString *)stringForProperty:(NSString *)property;
- (NSInteger)integerForProperty:(NSString *)property;
- (double)doubleForProperty:(NSString *)property;

#pragma mark - Commands

- (void)performCommand:(NSString *)command withArgument:(nullable NSString *)arg1 withArgument:(nullable NSString *)arg2 withArgument:(nullable NSString *)arg3;
- (void)performCommand:(NSString *)command withArgument:(nullable NSString *)arg1 withArgument:(nullable NSString *)arg2;
- (void)performCommand:(NSString *)command withArgument:(nullable NSString *)arg1;
- (void)performCommand:(NSString *)command;

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

