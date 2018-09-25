//
//  slh_media.h
//  Slash
//
//  Created by Terminator on 9/23/18.
//  Copyright © 2018 digital-pers0n. All rights reserved.
//

#ifndef slh_media_h
#define slh_media_h

#include <stdio.h>
#include <limits.h>
#include "slh_dictionary.h"

typedef enum  {
    CodecTypeVideo,
    CodecTypeAudio,
    CodecTypeText,
    CodecTypeUnknown = INT_MAX
} CodecType;

typedef struct _Stream {
    unsigned int index;
    CodecType codec_type;
    Dictionary *info;
} Stream;

/**
 * Get various information about the stream. 
 * 
 * @param key Stream key. Keys are declared in slh_media_keys.h. This parameter cannot be NULL.
 *
 * @return Value associated with the key or NULL.
 */
static inline char *stream_get_value(Stream *s, const char *key) {
    return dict_get_value(s->info, key);
}

static inline CodecType stream_codec_type(Stream *s) {
    return s->codec_type;
}

static inline unsigned int stream_index(Stream *s) {
    return s->index;
}

static inline Dictionary *stream_info(Stream *s) {
    return s->info;
}

typedef struct _Media {
    char *filename;
    char *format_name;
    unsigned int nb_streams;    // number of streams
    size_t size;                // media size in bytes
    size_t bit_rate;            // stream bit rate
    double duration;            // stream duration in seconds
    Dictionary *info;
    Stream *streams;
} Media;

/**
 * Initialize a media item.
 *
 * @param ffprobe_path Path to ffprobe executable. This parameter cannot be NULL.
 *
 * @param filename Path to a media file. This parameter cannot be NULL.
 *
 * @return 0 on success, otherwise -1 
 */ 
int media_init(Media *m, const char *ffprobe_path, const char *filename);

/**
 * Destroy the media item.
 */
void media_destroy(Media *m);

/**
 * Get metadata.
 *
 * @param key Metadata key. Keys are defined in slh_media_keys.h. This parameter cannot be NULL.
 *
 * @return Value associated with the key or NULL.
 */
static inline char *media_get_metadata(Media *m, const char *key) {
    return dict_get_value(m->info, key);
}

static inline char *media_filename(Media *m) {
    return m->filename;
}

static inline char *media_format_name(Media *m) {
    return m->format_name;
}

/**
 * Get number of streams.
 */
static inline unsigned int media_nb_streams(Media *m) {
    return m->nb_streams;
}

/**
 * Get bit rate in bps.
 */
static inline size_t media_bit_rate(Media *m) {
    return m->bit_rate;
}

/**
 * Get size in bytes.
 */
static inline size_t media_size(Media *m) {
    return m->size;
}

/**
 * Get duration in seconds.
 */
static inline double media_duration(Media *m) {
    return m->duration;
}

static inline Stream *media_streams(Media *m) {
    return m->streams;
}

static inline Dictionary *media_info(Media *m) {
    return m->info;
}


#endif /* slh_media_h */
