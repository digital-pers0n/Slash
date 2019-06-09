//
//  extern.m
//  Slash
//
//  Created by Terminator on 9/28/18.
//  Copyright © 2018 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - SLHPreferences

NSString *const SLHPreferencesFFMpegFilePathKey     = @"ffmpegBinary";
NSString *const SLHPreferencesFFProbeFilePathKey    = @"ffprobeBinary";
NSString *const SLHPreferencesMPVFilePathKey        = @"mpvBinary";
NSString *const SLHPreferencesNumberOfThreadsKey    = @"numberOfThreads";
NSString *const SLHPreferencesUpdateOutputNameKey   = @"updateOutputName";
NSString *const SLHPreferencesLastUsedFormatKey     = @"lastUsedFormat";
NSString *const SLHPreferencesRecentOutputPaths     = @"recentOutputPaths";
NSString *const SLHPreferencesOutputPathSameAsInput = @"outputPathSameAsInput";
NSString *const SLHPreferencesDefaultOutputPath     = @"~/Movies/";
NSString *const SLHPreferencesDefaultFFMpegPath     = @"/usr/local/bin/ffmpeg";
NSString *const SLHPreferencesDefaultFFProbePath    = @"/usr/local/bin/ffprobe";
NSString *const SLHPreferencesDefaultMPVPath        = @"/usr/local/bin/mpv";


#pragma mark - SLHMetadataItem

NSString *const SLHMetadataIdentifierArtist         = @"artist";
NSString *const SLHMetadataIdentifierTitle          = @"title";
NSString *const SLHMetadataIdentifierDate           = @"date";
NSString *const SLHMetadataIdentifierComment        = @"comment";

#pragma mark - SLHEncoderItem Keys

NSString *const SLHEncoderMediaMapKey             = @"-map";
NSString *const SLHEncoderMediaContainerKey       = @"-f";
NSString *const SLHEncoderMediaStartTimeKey       = @"-ss";
NSString *const SLHEncoderMediaEndTimeKey         = @"-t";
NSString *const SLHEncoderMediaNoSubtitlesKey     = @"-sn";
NSString *const SLHEncoderMediaNoAudioKey         = @"-an";
NSString *const SLHEncoderMediaNoVideoKey         = @"-vn";
NSString *const SLHEncoderMediaOverwriteFilesKey  = @"-y";
NSString *const SLHEncoderMediaThreadsKey         = @"-threads";
NSString *const SLHEncoderMediaPassKey            = @"-pass";
NSString *const SLHEncoderMediaPassLogKey         = @"-passlogfile";

NSString *const SLHEncoderVideoBitrateKey         = @"-b:v";
NSString *const SLHEncoderVideoMaxBitrateKey      = @"-maxrate";
NSString *const SLHEncoderVideoBufsizeKey         = @"-bufsize";
NSString *const SLHEncoderVideoCRFBitrateKey      = @"-crf";
NSString *const SLHEncoderVideoCodecKey           = @"-c:v";
NSString *const SLHEncoderVideoFiltersKey         = @"-vf";
NSString *const SLHEncoderVideoScaleSizeKey       = @"-s";
NSString *const SLHEncoderVideoMovflagsKey        = @"-movflags";
NSString *const SLHEncoderVideoPixelFormatKey     = @"-pix_fmt";
NSString *const SLHEncoderVideoAspectRatioKey     = @"-aspect";

NSString *const SLHEncoderVideoH264ProfileKey     = @"-profile:v";
NSString *const SLHEncoderVideoH264LevelKey       = @"-level:v";
NSString *const SLHEncoderVideoH264PresetKey      = @"-preset";
NSString *const SLHEncoderVideoH264TuneKey        = @"-tune";

NSString *const SLHEncoderVideoVPXSpeedKey        = @"-cpu-used";
NSString *const SLHEncoderVideoVPXQualityKey      = @"-deadline";
NSString *const SLHEncoderVideoVPXAutoAltRefKey   = @"-auto-alt-ref";
NSString *const SLHEncoderVideoVPXRcLookaheadKey  = @"-lag-in-frames";
NSString *const SLHEncoderVideoVP9RowMTKey        = @"-row-mt";
NSString *const SLHEncoderVideoVP9TileColumnsKey  = @"-tile-columns";
NSString *const SLHEncoderVideoVP9TileRowsKey     = @"-tile-rows";
NSString *const SLHEncoderVideoVP9FrameParallelKey    = @"-frame-parallel";

NSString *const SLHEncoderAudioCodecKey           = @"-c:a";
NSString *const SLHEncoderAudioBitrateKey         = @"-b:a";
NSString *const SLHEncoderAudioQualityKey         = @"-aq";
NSString *const SLHEncoderAudioFiltersKey         = @"-af";
NSString *const SLHEncoderAudioSampleRateKey      = @"-ar";
NSString *const SLHEncoderAudioChannelsKey        = @"-ac";

#pragma mark - SLHEncoderItem Filter Keys

NSString *const SLHEncoderVideoFilterCropKey           = @"crop";
NSString *const SLHEncoderVideoFilterDeinterlaceKey    = @"yadif";
NSString *const SLHEncoderAudioFilterFadeInKey         = @"afade=t=in";
NSString *const SLHEncoderAudioFilterFadeOutKey        = @"afade=t=out";
NSString *const SLHEncoderAudioFilterPreampKey         = @"acompressor";
