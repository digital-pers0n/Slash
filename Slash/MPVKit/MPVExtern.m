//
//  MPVExtern.m
//  Slash
//
//  Created by Terminator on 2019/10/12.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - Commands

NSString * const MPVPlayerCommandLoadFile           = @"loadfile";
NSString * const MPVPlayerCommandStop               = @"stop";
NSString * const MPVPlayerCommandFrameBackStep      = @"frame-back-step";
NSString * const MPVPlayerCommandFrameStep          = @"frame-step";
NSString * const MPVPlayerCommandScreenshot         = @"screenshot";
NSString * const MPVPlayerCommandScreenshotToFile   = @"screenshot-to-file";

#pragma mark - Properties

NSString * const MPVPlayerPropertyMute                  = @"mute";
NSString * const MPVPlayerPropertySpeed                 = @"speed";
NSString * const MPVPlayerPropertyTimePosition          = @"time-pos";
NSString * const MPVPlayerPropertyPercentPosition       = @"percent-pos";
NSString * const MPVPlayerPropertyVolume                = @"volume";
NSString * const MPVPlayerPropertyPause                 = @"pause";
NSString * const MPVPlayerPropertyFilename              = @"filename";
NSString * const MPVPlayerPropertyDuration              = @"duration";
NSString * const MPVPlayerPropertyABLoopA               = @"ab-loop-a";
NSString * const MPVPlayerPropertyABLoopB               = @"ab-loop-b";
NSString * const MPVPlayerPropertyVideoID               = @"vid";
NSString * const MPVPlayerPropertyAudioID               = @"aid";
NSString * const MPVPlayerPropertySubtitleID            = @"sid";
NSString * const MPVPlayerPropertyScreenshotDirectory   = @"screenshot-directory";
NSString * const MPVPlayerPropertyScreenshotFormat      = @"screenshot-format";
NSString * const MPVPlayerPropertyScreenshotTemplate    = @"screenshot-template";
NSString * const MPVPlayerPropertyOSDLevel              = @"osd-level";
NSString * const MPVPlayerPropertyOSDFractions          = @"osd-fractions";

#pragma mark - Notifications

NSString * const MPVPlayerWillShutdownNotification          = @"playerWillShutdown";
NSString * const MPVPlayerWillStartPlaybackNotification     = @"playerWillStartPlayback";
NSString * const MPVPlayerDidEndPlaybackNotification        = @"playerDidEndPlayback";
NSString * const MPVPlayerDidLoadFileNotification           = @"playerDidLoadFile";
NSString * const MPVPlayerDidEnterIdleModeNotification      = @"playerDidEnterIdleMode";
NSString * const MPVPlayerVideoDidChangeNotification        = @"playerVideoDidChange";
NSString * const MPVPlayerDidStartSeekNotification          = @"playerDidStartSeek";
NSString * const MPVPlayerDidRestartPlaybackNotification    = @"playerDidRestartPlayback";
