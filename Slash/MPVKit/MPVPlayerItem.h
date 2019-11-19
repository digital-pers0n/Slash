//
//  MPVPlayerItem.h
//  Slash
//
//  Created by Terminator on 2019/10/21.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @enum MPVPlayerItemStatus
 * @abstract Indicate if an item can be successfully played.
 */
typedef NS_ENUM(NSInteger, MPVPlayerItemStatus) {

    /**
     * @constant MPVPlayerItemStatusUnknown
     * Indicate that the status of the item is unknown because it hasn't been loaded yet
     */
    MPVPlayerItemStatusUnknown,
    
    /**
     * @constant MPVPlayerItemStatusReadyToPlay
     * Indicate that the item can be played.
     */
    MPVPlayerItemStatusReadyToPlay,
    
    /**
     * @constant MPVPlayerItemStatusFailed
     * Indicate that the item can not be played because of an error.
     */
    MPVPlayerItemStatusFailed
};

@class MPVPlayerItemTrack;
@class MPVMetadataItem;


/**
 * @class MPVPlayerItem
 *
 * @abstract Media files representation.
 */

@interface MPVPlayerItem : NSObject

- (instancetype)init NS_UNAVAILABLE;

/**
 * Create an instance of MPVPlayerItem for playing a media file.
 * @param path Media file path
 * @return An instance of MPVPlayerItem
 */
+ (instancetype)playerItemWithPath:(NSString *)path;

/**
 * Create an instance of MPVPlayerItem.
 * @param url an url to a media resource
 * @return an instance of MPVPlayerItem
 */
+ (instancetype)playerItemWithURL:(NSURL *)url;

/**
 * Initialize an MPVPlayerItem with a file path.
 * @param path Media file path
 * @return An instance of MPVPlayerItem
 */
- (instancetype)initWithPath:(NSString *)path;


/** 
 * Initialize an MPVPlayerItem object with a given url.
 * @param url an url to a media resource
 * @return An instance of MPVPlayerItem
 */
- (instancetype)initWithURL:(NSURL *)url;

/**
 * Media item status.
 */
@property (readonly, nonatomic) MPVPlayerItemStatus status;

/**
 * Get the error with a description of what caused failure to initialize the player item.
 * @return if the status property is equal to MPVPlayerItemStatusFailed, return an instance of NSError or nil otherwise.
 */
@property (readonly, nullable, nonatomic) NSError *error;

/**
 * The tracks in a media file.
 * @return An array of tracks the media file contains.
 */
@property (readonly, nonatomic) NSArray <MPVPlayerItemTrack *> *tracks;

/**
 * Metadata stored by the media file.
 * @return An array of MPVMetadataItem objects.
 */
@property (readonly, nonatomic) NSArray <MPVMetadataItem *> *metadata;

/**
 * Media URL
 */
@property (readonly, nonatomic) NSURL *url;

/**
 * Media file path
 * @note Same as MPVPlayerItem.url.path
 */
@property (readonly, nonatomic) NSString *filePath;

/**
 * Media format name
 */
@property (readonly, nonatomic) NSString *formatName;

/**
 * Media file size (in bytes)
 */
@property (readonly, nonatomic) uint64_t fileSize;

/**
 * Media bitrate (in bps)
 */
@property (readonly, nonatomic) NSUInteger bitRate;

/**
 * Media duration (in seconds)
 */
@property (readonly, nonatomic) double duration;

@end

NS_ASSUME_NONNULL_END
