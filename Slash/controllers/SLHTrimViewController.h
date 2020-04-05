//
//  SLHTrimViewController.h
//  Slash
//
//  Created by Terminator on 2020/03/23.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class MPVPlayer, SLHEncoderItem;

@interface SLHTrimViewController : NSViewController

@property (nonatomic, weak, nullable) MPVPlayer *player;
@property (nonatomic, weak, nullable) SLHEncoderItem *encoderItem;

/** Trim View vertical zoom. 1.0 == 100px Default is 0.5 */
@property (nonatomic) IBInspectable CGFloat verticalZoom;

/** Trim View horizontal zoom. 1.0 == 200px Default is 3.0 */
@property (nonatomic) IBInspectable CGFloat horizontalZoom;

/** Indicate if preview images should be generated and displayed. Default is NO */
@property (nonatomic) IBInspectable BOOL shouldDisplayPreviewImages;

/** Indicate if the generation of preview images is in progress. */
@property (nonatomic, readonly) BOOL busy;

/** 
 The name to use when autosaving to the user defaults, the values such as 
 vertical zoom, horizontal zoom and if preview images should be generated.
 If this value is nil or the string is empty no autosaving is done. 
 */
@property (nonatomic, nullable) IBInspectable NSString *autosaveName;

@end

NS_ASSUME_NONNULL_END
