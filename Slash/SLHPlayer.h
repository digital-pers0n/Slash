//
//  SLHPlayer.h
//  Slash
//
//  Created by Terminator on 2018/08/14.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SLHMediaItem;
@protocol SLHPlayerDelegate;

NS_ASSUME_NONNULL_BEGIN

/**
  @enum SLHPlayerStatus
  @abstract 
    SLHPlayer status property values. Indicate if a player can play items.

  @constant SLHPlayerStatusReadyToPlay 
  @abstract The player is ready to play media items.
  
  @constant SLHPlayerStatusFailed 
  @abstract The player can not play media items becuase of an error. The error described by the value of the player's error property.
 
  @constant SLHPlayerStatusUnknown
  @abstract The player was initialized without an SLHMediaItem instance.
*/
typedef NS_ENUM(NSInteger, SLHPlayerStatus) {
    SLHPlayerStatusReadyToPlay,
    SLHPlayerStatusFailed,
    SLHPlayerStatusUnknown
};

/**
   @class SLHPlayer

   @abstract
    SLHPlayer provides a playback interface for media files using MPV player
*/
@interface SLHPlayer : NSObject

/**
  Return an instance of SLHPlayer and implicitly create an SLHMediaItem.

  @param path Media file path
  @return An instance of SLHPlayer
 */
+ (instancetype)playerWithPath:(NSString *)path;

/**
  Create an SLHPlayer instance.
  @param item An instance of SLHMediaItem 
  @return An instance of SLHPlayer
*/
+ (instancetype)playerWithMediaItem:(nullable SLHMediaItem *)item;

/**
  Initialize an SLHPlayer and implicitly create an SLHMediaItem instance.
  @param path file path
  @return An instance of SLHPlayer
*/
- (instancetype)initWithPath:(NSString *)path;

/**
  Initialize an SLHPlayer instance.
  @param item An instance of SLHMediaItem
  @return An instance of SLHPlayer
*/
- (instancetype)initWithMediaItem:(nullable SLHMediaItem *)item;

/**
  The player's delegate.
*/
@property (nullable) id <SLHPlayerDelegate> delegate;

/**
  The player's status.
*/
@property (readonly) SLHPlayerStatus status;

/**
  @return an NSError if the player's status is SLHPlayerStatusFailed, nil otherwise.
*/
@property (readonly, nullable) NSError *error;

/* Playback control */

/**
  Begin playback
*/
- (void)play;

/**
  Pause playback.
*/
- (void)pause;

/* Media Item control */
 
/**
  Indicate the current item 
*/
@property (readonly, nullable) SLHMediaItem *currentItem;

/**
  Replace the current item with the specified item.
  @param item An instance of SLHMediaItem that will become current item.
*/
- (void)replaceCurrentItemWithMediaItem:(SLHMediaItem *)item;

/* Time Control */

/**
  @return The playback position of the current item
*/
- (double)currentTime;

/**
  Seek to a specified time of the current item
*/
- (void)seekToTime:(double)time;

@end

@protocol SLHPlayerDelegate <NSObject>

- (void)player:(SLHPlayer *)p segmentStart:(double)start;
- (void)player:(SLHPlayer *)p segmentEnd:(double)end;
- (void)playerDidAddNewSegment:(SLHPlayer *)p;
- (void)playerDidClearSegment:(SLHPlayer *)p;

@end

NS_ASSUME_NONNULL_END
