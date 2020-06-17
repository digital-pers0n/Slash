//
//  SLHEncoderItem.h
//  Slash
//
//  Created by Terminator on 2018/11/15.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SLHEncoderItemOptions, SLHFilterOptions, SLHEncoderItemMetadata;
@class MPVPlayerItem;

NS_ASSUME_NONNULL_BEGIN

typedef struct time_interval {
    double start;
    double end;
} TimeInterval;

@interface SLHEncoderItem : NSObject <NSCopying>

- (instancetype)initWithPlayerItem:(MPVPlayerItem *)item outputPath:(NSString *)outputMediaPath;

@property (nonatomic) MPVPlayerItem *playerItem;

- (void)matchSource;

@property NSString *outputPath;
@property NSString *outputFileName;
@property NSString *container;

@property TimeInterval interval;

@property NSInteger videoStreamIndex;
@property NSInteger audioStreamIndex;
@property NSInteger subtitlesStreamIndex;

@property (nonatomic) SLHEncoderItemOptions *videoOptions;
@property (nonatomic) SLHEncoderItemOptions *audioOptions;

@property SLHFilterOptions *filters;

@property BOOL twoPassEncoding;

@property SLHEncoderItemMetadata *metadata;

@property NSInteger tag;

@property NSArray <NSArray *> *encoderArguments;

/* Cocoa Bindings */
@property double intervalStart;
@property double intervalEnd;

/** Duration of a segment (seconds) */
@property (readonly, nonatomic) double duration;

/** Estimated output file size (bytes) */
@property (readonly, nonatomic) uint64_t estimatedSize;


#pragma mark - Preview Images
/** 
 Set how many preview images to generate.
 This is only a hint. The actual number of preview images may be lower.
 Default value is 50. Must be greater than zero.
 */
@property (class, nonatomic) NSUInteger defaultNumberOfPreviewImages;

/** 
 Set the maximum height of a preview image.
 The width will be proportionally scaled to match the height.
 Default value is 128. Must be greater than zero.
 */
@property (class, nonatomic) NSUInteger defaultPreviewImageHeight;

/** 
 Array that contains CGImageRef images for the video file.
 Default is nil. Filled if the @c -generatePreviewImagesWithBlock: was successful. 
 */
@property (nonatomic, nullable, readonly) NSArray * previewImages;

/** 
 Asynchronously generate preview images. You should check that the @c playerItem
 property is not nil and it has video tracks.
 @param responseBlock Called from a backgorund thread when all background 
                      operations are done. The BOOL parameter indicates if
                      the operation was successful.
 */
- (void)generatePreviewImagesWithBlock:(void (^)(BOOL success))responseBlock;
 
@end

NS_ASSUME_NONNULL_END
