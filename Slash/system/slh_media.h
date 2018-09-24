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

static inline char *stream_get_value(Stream *s, const char *key) {
    return dict_get_value(s->info, key);
};

static inline CodecType stream_codec_type(Stream *s) {
    return s->codec_type;
};

static inline unsigned int stream_index(Stream *s) {
    return s->index;
}

static inline Dictionary *stream_info(Stream *s) {
    return s->info;
}

typedef struct _Media {
    char *filename;
    char *format_name;
    unsigned int nb_streams;
    size_t size;
    size_t bit_rate;
    double duration;
    Dictionary *info;
    Stream *streams;
} Media;

int media_init(Media *m, const char *ffprobe_path, const char *filename);
void media_destroy(Media *m);

static inline char *media_filename(Media *m) {
    return m->filename;
}

static inline char *media_format_name(Media *m) {
    return m->format_name;
}

static inline unsigned int media_nb_streams(Media *m) {
    return m->nb_streams;
}

static inline size_t media_bit_rate(Media *m) {
    return m->bit_rate;
}

static inline size_t media_size(Media *m) {
    return m->size;
}

static inline double media_duration(Media *m) {
    return m->duration;
}

static inline Stream *media_streams(Media *m) {
    return m->streams;
}


#endif /* slh_media_h */
