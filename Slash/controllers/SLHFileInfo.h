//
//  SLHFileInfo.h
//  Slash
//
//  Created by Terminator on 2019/11/16.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class MPVPlayerItem;

@interface SLHFileInfo : NSViewController

+ (instancetype)fileInfo;

@property (nonatomic) MPVPlayerItem *playerItem;

@end

NS_ASSUME_NONNULL_END
