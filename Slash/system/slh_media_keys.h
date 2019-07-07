//
//  slh_media_keys.h
//  Slash
//
//  Created by Terminator on 9/25/18.
//  Copyright © 2018 digital-pers0n. All rights reserved.
//

#ifndef slh_media_keys_h
#define slh_media_keys_h



/* Stream Keys */

extern const char *kMediaStreamIndexKey;                // index of stream
extern const char *kMediaStreamCodecNameKey;            // codec name
extern const char *kMediaStreamCodecTypeKey;            // codec type
extern const char *kMediaStreamWidthKey;                // video: width
extern const char *kMediaStreamHeightKey;               // video: height
extern const char *kMediaStreamDisplayAspectRatioKey;   // video: aspect ratio
extern const char *kMediaStreamPixFormatKey;            // video: pixel format
extern const char *kMediaStreamProfileKey;              // encoding profile
extern const char *kMediaStreamDurationKey;             // stream duration
extern const char *kMediaStreamBitRateKey;              // stream bit rate
extern const char *kMediaStreamMaxBitrateKey;           // stream max bit rate
extern const char *kMediaStreamSampleRateKey;           // audio: sample rate
extern const char *kMediaStreamChannelsKey;             // audio: number of channels
extern const char *kMediaStreamChannelLayoutKey;        // audio: channel layout
extern const char *kMediaStreamFramerateKey;

extern const char *kMediaStreamCodedWidthKey;
extern const char *kMediaStreamCodedHeightKey;
extern const char *kMediaStreamSampleAspectRatioKey;
extern const char *kMediaStreamRFramerateKey;

/* Metadata Keys */

extern const char *kMediaMetadataTitleKey;
extern const char *kMediaMetadataArtistKey;
extern const char *kMediaMetadataDateKey;
extern const char *kMediaMetadataCommentKey;
extern const char *kMediaMetadataLanguageKey;       // audio/subtitles language

/* Media Keys */

extern const char *kMediaFilenameKey;       // filename
extern const char *kMediaFormatNameKey;     // format descriptioon
extern const char *kMediaDurationKey;       // duration in seconds
extern const char *kMediaBitRateKey;        // bit rate
extern const char *kMediaSizeKey;           // size in bytes
extern const char *kMediaStreamsKey;        // number of streams

#endif /* slh_media_keys_h */
