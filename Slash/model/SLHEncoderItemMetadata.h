//
//  SLHEncoderMetadata.h
//  Slash
//
//  Created by Terminator on 2019/04/30.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>
@class SLHMediaItem;
@class MPVPlayerItem;

@interface SLHEncoderItemMetadata : NSObject <NSCopying>

- (instancetype)initWithPlayerItem:(MPVPlayerItem *)item;

@property NSString *artist;
@property NSString *title;
@property NSString *date;
@property NSString *comment;

- (NSArray <NSString *>*)arguments;

@end
