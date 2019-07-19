//
//  SLHMediaItem.h
//  Slash
//
//  Created by Terminator on 2018/08/14.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** 
 * @class SLHMediaItem
 *
 * @abstract Media files representation.
 */

/**
 * @enum SLHMediaItemStatus
 * @abstract Indicate if an item can be successfully played.
 *
 * @constant SLHMediaItemStatusReadyToPlay
 * Indicate that the item can be played.
 *
 * @constant SLHMediaItemStatusFailed
 * Indicate that the item can no longer be played.
 */
typedef NS_ENUM(NSInteger, SLHMediaItemStatus) {
    SLHMediaItemStatusReadyToPlay,
    SLHMediaItemStatusFailed
};

@class SLHMediaItemTrack;
@class SLHMetadataItem;

@interface SLHMediaItem : NSObject

/**
 * Create an instance of SLHMediaItem for playing a media file.
 * @param path Media file path
 * @return An instance of SLHMediaItem
 */
+ (instancetype)mediaItemWithPath:(NSString *)path;

/**
 * Initialize an SLHMediaItem with a file path.
 * @param path Media file path
 * @return An instance of SLHMediaItem
 */
- (instancetype)initWithPath:(NSString *)path;

/**
 * Media item status.
 */
@property (readonly) SLHMediaItemStatus status;

/**
 * The error that caused the failure.
 * @return if status is SLHMediaItemStatusFailed, return an instance of NSError or nil otherwise.
 */
@property (readonly, nullable) NSError *error;

/**
 * The tracks in a media file.
 * @return An array of tracks the media file contains.
 */
@property (readonly) NSArray<SLHMediaItemTrack *> *tracks;

/**
 * Metadata stored by the media file.
 * @return An array of SLHMetadataItem objects.
 */
@property (copy) NSArray<SLHMetadataItem *> *metadata;

/**
 * Media file path
 */
@property (readonly) NSString *filePath;

/**
 * Media format name
 */
@property (readonly) NSString *formatName;

/**
 * Media file size (in bytes)
 */
@property (readonly) NSUInteger fileSize;

/**
 * Media bitrate (in bps)
 */
@property (readonly) NSUInteger bitRate;

/**
 * Media duration (in seconds)
 */
@property (readonly) double duration;

@end

NS_ASSUME_NONNULL_END
