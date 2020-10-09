//
//  SLHEncoderMetadata.h
//  Slash
//
//  Created by Terminator on 2019/04/30.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>
@class MPVPlayerItem;

@interface SLHEncoderItemMetadata : NSObject <NSCopying>

- (instancetype)initWithPlayerItem:(MPVPlayerItem *)item;

@property (nonatomic, copy) NSString *artist;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *date;
@property (nonatomic, copy) NSString *comment;

- (NSArray <NSString *>*)arguments;

@end
