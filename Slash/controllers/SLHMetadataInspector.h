//
//  SLHMetadataInspector.h
//  Slash
//
//  Created by Terminator on 2019/11/17.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class SLHEncoderItem;

@interface SLHMetadataInspector : NSViewController

+ (instancetype)metadataInspector;

@property (nonatomic) SLHEncoderItem *encoderItem;

@end

NS_ASSUME_NONNULL_END
