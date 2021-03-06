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
@property BOOL enableVideoFilters;
@property NSInteger videoCropX;
@property NSInteger videoCropY;
@property NSInteger videoCropWidth;
@property NSInteger videoCropHeight;
@property (nonatomic) NSRect videoCropRect;
@property BOOL videoDeinterlace;
@property BOOL burnSubtitles;
@property NSString *subtitlesPath;
@property BOOL forceSubtitlesStyle;
@property NSString *subtitlesStyle;
@property NSString *additionalVideoFiltersString;

// Audio
@property BOOL enableAudioFilters;
@property double audioFadeIn;
@property double audioFadeOut;
@property NSInteger audioPreamp;
@property NSString *additionalAudioFiltersString;

@end
