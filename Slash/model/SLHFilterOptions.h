//
//  SLHFilterOptions.h
//  Slash
//
//  Created by Terminator on 2019/03/26.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SLHFilterOptions : NSObject <NSCopying>

// Video
@property NSInteger videoCropX;
@property NSInteger videoCropY;
@property NSInteger videoCropWidth;
@property NSInteger videoCropHeight;
@property BOOL videoDeinterlace;

// Audio
@property double audioFadeIn;
@property double audioFadeOut;
@property NSInteger audioPreamp;

@end
