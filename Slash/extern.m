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
NSString *const SLHPreferencesMPVFilePathKey        = @"mpvBinary";
NSString *const SLHPreferencesFFMpegPathKey         = @"ffmpegPath";
NSString *const SLHPreferencesMPVPathKey            = @"mpvPath";
NSString *const SLHPreferencesNumberOfThreadsKey    = @"numberOfThreads";
NSString *const SLHPreferencesUpdateOutputNameKey   = @"updateOutputName";
NSString *const SLHPreferencesLastUsedFormatKey     = @"lastUsedFormat";
NSString *const SLHPreferencesRecentOutputPaths     = @"recentOutputPaths";
NSString *const SLHPreferencesOutputPathSameAsInput = @"outputPathSameAsInput";
NSString *const SLHPreferencesDefaultOutputPath     = @"~/Movies/";
NSString *const SLHPreferencesDefaultFFMpegPath     = @"/usr/local/bin/ffmpeg";
NSString *const SLHPreferencesDefaultMPVPath        = @"/usr/local/bin/mpv";

NSString * const SLHPreferencesDefaultScreenshotPath        = @"~/Pictures/";
NSString * const SLHPreferencesDefaultScreenshotFormat      = @"png";
NSString * const SLHPreferencesDefaultScreenshotTemplate    = @"%F-%wH-%wM-%wS.%wT";
NSString * const SLHPreferencesScreenshotPathKey            = @"screenshotPath";
NSString * const SLHPreferencesScreenshotFormatKey          = @"screenshotFormat";
NSString * const SLHPreferencesScreenshotTemplateKey        = @"screenshotTemplate";
NSString * const SLHPreferencesScreenshotJPGQualityKey      = @"screenshotJPGQuality";
NSString * const SLHPreferencesScreenshotPNGCompressionKey  = @"screenshotPNGCompression";

NSString * const SLHPreferencesOSDFontNameKey                   = @"osdFontName";
NSString * const SLHPreferencesOSDFontSizeKey                   = @"osdFontSize";
NSString * const SLHPreferencesOSDFontScaleByWindowKey          = @"osdFontScaleByWindow";
NSString * const SLHPreferencesSubtitlesFontNameKey             = @"subtitlesFontName";
NSString * const SLHPreferencesSubtitlesFontSizeKey             = @"subtitlesFontSize";
NSString * const SLHPreferencesSubtitlesFontScaleByWindowKey    = @"subtitlesFontScaleByWindow";

NSString * const SLHPreferencesAdvancedOptionNameKey        = @"key";
NSString * const SLHPreferencesAdvancedOptionValueKey       = @"value";
NSString * const SLHPreferencesAdvancedOptionsKey           = @"advancedOptions";
NSString * const SLHPreferencesAdvancedOptionsEnabledKey    = @"enableAdvancedOptions";
NSString * const SLHPreferencesAdvancedOptionsLastEditedKey = @"lastEditedAdvancedOption";

NSString * const SLHPreferencesWindowTitleStyleKey = @"windowTitleStyle";

NSString * const SLHPreferencesUseHiResOpenGLSurfaceKey = @"useHiResOpenGLSurface";
NSString * const SLHPreferencesPausePlaybackDuringWindowResizeKey = @"pausePlaybackDuringWindowResize";

NSString * const SLHPreferencesTrimViewShouldGeneratePreviewImagesKey = @"trimViewShouldGeneratePreviewImages";
NSString * const SLHPreferencesTrimViewVerticalZoomKey = @"trimViewVerticalZoom";
NSString * const SLHPreferencesTrimViewHorizontalZoomKey = @"trimViewHorizontalZoom";

NSString * const SLHPreferencesShouldOverwriteFiles = @"shouldOverwriteFiles";

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
NSString *const SLHEncoderVideoPixelFormatKey     = @"-pix_fmt";
NSString *const SLHEncoderVideoAspectRatioKey     = @"-aspect";
NSString *const SLHEncoderVideoMaxGopSizeKey      = @"-g";

NSString *const SLHEncoderVideoH264ProfileKey     = @"-profile:v";
NSString *const SLHEncoderVideoH264LevelKey       = @"-level:v";
NSString *const SLHEncoderVideoH264PresetKey      = @"-preset";
NSString *const SLHEncoderVideoH264TuneKey        = @"-tune";
NSString *const SLHEncoderVideoH264MovflagsKey    = @"-movflags";
NSString *const SLHEncoderVideoH264LookAheadKey    = @"-rc-lookahead";

NSString *const SLHEncoderVideoVPXSpeedKey        = @"-cpu-used";
NSString *const SLHEncoderVideoVPXQualityKey      = @"-deadline";
NSString *const SLHEncoderVideoVPXAutoAltRefKey   = @"-auto-alt-ref";
NSString *const SLHEncoderVideoVPXLagInFramesKey  = @"-lag-in-frames";
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

NSString *const SLHEncoderFiltersVideoCropKey           = @"crop";
NSString *const SLHEncoderFiltersVideoDeinterlaceKey    = @"yadif";
NSString *const SLHEncoderFiltersAudioFadeInKey         = @"afade=t=in";
NSString *const SLHEncoderFiltersAudioFadeOutKey        = @"afade=t=out";
NSString *const SLHEncoderFiltersAudioPreampKey         = @"acompressor";

#pragma mark - SLHEncoderPreset

NSString *const SLHEncoderPresetNameKey            = @"encoderPresetName";
NSString *const SLHEncoderVideoH264EncodingTypeKey = @"encodingType";
NSString *const SLHEncoderVideoH264FaststartKey    = @"faststart";
NSString *const SLHEncoderVideoH264ZerolatencyKey  = @"zerolatency";
NSString *const SLHEncoderVideoH264FastdecodeKey   = @"fastdecode";
NSString *const SLHEncoderVideoH264ContainerTypeKey = @"containerType";

NSString *const SLHEncoderVideoVPXEnableTwoPassKey = @"enableTwoPass";
NSString *const SLHEncoderVideoVPXEnableCRFKey     = @"enableCRF";
NSString *const SLHEncoderVideoVPXUseVorbisAudioKey = @"useVorbisAudio";

NSString *const SLHEncoderUniversalVideoArgumentsKey = @"videoArguments";
NSString *const SLHEncoderUniversalAudioArgumentsKey = @"audioArguments";

NSString *const SLHEncoderFiltersEnableVideoFiltersKey        = @"enableVideoFilters";
NSString *const SLHEncoderFiltersEnableAudioFiltersKey        = @"enableAudioFilters";
NSString *const SLHEncoderFiltersBurnSubtitlesKey             = @"burnSubtitles";
NSString *const SLHEncoderFiltersForceSubtitlesStyleKey       = @"forceSubtitlesStyle";
NSString *const SLHEncoderFiltersSubtitlesStyleKey            = @"subtitlesStyle";
NSString *const SLHEncoderFiltersAdditionalVideoFiltersKey    = @"additionalVideoFilters";
NSString *const SLHEncoderFiltersAdditionalAudioFiltersKey    = @"additionalAudioFilters";

#pragma mark - SLHMainWindowController

NSString *const SLHEncoderFormatDidChangeNotification = @"encoderFormatDidChange";

#pragma mark - SLHPlayerViewController Notifications

NSString * const SLHPlayerViewControllerDidChangeInMarkNotification         = @"playerViewControllerDidChangeInMark";
NSString * const SLHPlayerViewControllerDidChangeOutMarkNotification        = @"playerViewControllerDidChangeOutMark";
NSString * const SLHPlayerViewControllerDidCommitInOutMarksNotification     = @"playerViewControllerDidCommitInOutMarks";
