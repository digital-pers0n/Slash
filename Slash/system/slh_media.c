//
//  slh_media.c
//  Slash
//
//  Created by Terminator on 9/23/18.
//  Copyright © 2018 digital-pers0n. All rights reserved.
//

#include "slh_media.h"
#include <stdlib.h>
#include <string.h>

extern const char *kMediaStreamIndexKey;
extern const char *kMediaStreamCodecNameKey;
extern const char *kMediaStreamCodecTypeKey;
extern const char *kMediaFormatNameKey;
extern const char *kMediaDurationKey;
extern const char *kMediaBitRateKey;
extern const char *kMediaSizeKey;
extern const char *kMediaStreamsKey;


#pragma mark - utilites

/**
 Locate character and its index inside a string.
 
 @return A pointer to the located character, or NULL.
 */
static inline char *stridx(const char *str, size_t *idx, int ch) {
    size_t count = 0;
    while (*str) {
        if (*str == ch) {
            *idx = count;
            return (char *)str;
        }
        count++;
        str++;
    }
    return NULL;
}

/**
 Duplicate a string and if it has '\n' character
 at the end, replace it with '\0'. 
 The copy of the string can be used as an argument to the free() function.
 
 @return A pointer to a copy of the string, or NULL if error occurs.
 */
static inline char *strdup2(const char *src) {
    size_t len = strlen(src);
    char *ret, *nl;
    ret = malloc(sizeof(char) * len + 1);
    if (!ret) {
        return NULL;
    }
    strncpy(ret, src, len);
    if (*(nl = ret + (len - 1)) == '\n') {
        *nl = '\0';
    }
    return ret;
}


static inline int is_stream(const char *str) {
    return (str[0] == '[' && str[1] == 'S' && str[2] == 'T');
}

static inline int is_format(const char *str) {
    return (str[0] == '[' && str[1] == 'F' && str[2] == 'O');
}

#pragma mark - Stream functions

/**
 Initialize a stream object.
 */
static int stream_init(Stream *s) {
    s->info = malloc(sizeof(Dictionary));
    return dict_init(s->info, free);
}

/**
 Destroy the stream object.
 */
static void stream_destroy(Stream *s) {
    dict_destroy(s->info);
    free(s->info);
}

#pragma mark - Media Initialize

static const size_t kBufSize = 512;    // buffer size

/**
 Initialize info dictionary.
 
 @param ffp Path to ffprobe executable.
 
 @return 0 on success, otherwise -1
 */
static int media_format_init(Media *m, const char *ffp) {
    m->info = malloc(sizeof(Dictionary));
    dict_init(m->info, free);
    char *buffer = malloc(sizeof(char) * kBufSize);
    char *cmd;
    asprintf(&cmd, "%s -show_format -i \"%s\" -v error", ffp, media_filename(m));
    FILE *fp = popen(cmd, "r");
    
    while (fgets(buffer, kBufSize, fp)) {
        if (is_format(buffer)) {
            while (fgets(buffer, kBufSize, fp)) {
                size_t idx = 0;
                char *cp = stridx(buffer, &idx, '=');
                if (cp) {
                    char *key = strndup(buffer, idx);
                    dict_add_value(media_info(m), key, strdup2(cp + 1));
                    free(key);
                } else {
                    break;
                }
            }
        }
    }
    
    {
        m->format_name = dict_get_value(media_info(m), kMediaFormatNameKey);
        char *val = dict_get_value(media_info(m), kMediaStreamsKey);
        if (val) {
            m->nb_streams = atoi(val);
        }
        val = dict_get_value(media_info(m), kMediaDurationKey);
        if (val) {
            m->duration = strtod(val, 0);
        }
        val = dict_get_value(media_info(m), kMediaSizeKey);
        if (val) {
            m->size = strtol(val, 0, 10);
        }
        val = dict_get_value(media_info(m), kMediaBitRateKey);
        if (val) {
            m->bit_rate = strtol(val, 0, 10);
        }
    }
    
    pclose(fp);
    free(cmd);
    free(buffer);
    return 0;
}

/**
 Initialize streams array.
 @param ffp Path to ffprobe executable
 */
static void media_streams_init(Media *m, const char *ffp) {
    char *buffer = malloc(sizeof(char) * kBufSize);
    char *cmd;
    asprintf(&cmd, "%s -show_streams -i \"%s\" -v error", ffp, media_filename(m));
    FILE *fp = popen(cmd, "r");
    
    int nb_streams = 0;
    Stream *streams = media_streams(m);
    
    while (fgets(buffer, kBufSize, fp)) {
        if (is_stream(buffer)) {
            // Stream *st = &(streams[nb_streams++]);
            Stream *st = streams + nb_streams++;
            while (fgets(buffer, kBufSize, fp)) {
                size_t idx = 0;
                char *cp = stridx(buffer, &idx, '=');
                if (cp) {
                    char *key  = strndup(buffer, idx);
                    dict_add_value(stream_info(st), key, strdup2(cp + 1));
                    free(key);
                } else {
                    break;
                }
            }
            
            char *val = stream_get_value(st, kMediaStreamIndexKey);
            if (val) {
                st->index = atoi(val);
            }
            
            val = stream_get_value(st, kMediaStreamCodecTypeKey);
            if (val) {
                if (strcmp("video", val) == 0) {
                    st->codec_type = CodecTypeVideo;
                } else if (strcmp("audio", val) == 0) {
                    st->codec_type = CodecTypeAudio;
                } else if (strcmp("subtitle", val) == 0) {
                    st->codec_type = CodecTypeText;
                } else {
                    st->codec_type = CodecTypeUnknown;
                }
                
            }
        }
    }
    pclose(fp);
    free(cmd);
    free(buffer);
}

int media_init(Media *m, const char *ffp, const char *fn) {
    if (!ffp || !fn) {
        fprintf(stderr, "%s: invalid argument.\n", __func__);
        return -1;
    }
    
    m->filename = strdup(fn);
    m->nb_streams = 0;
    m->streams = NULL;
    media_format_init(m, ffp);
    
    if (media_nb_streams(m) > 0) {
        Stream *streams = malloc(sizeof(Stream) * media_nb_streams(m));
        for (int i = 0; i < media_nb_streams(m); i++) {
            stream_init(streams + i);
        }
        media_streams_init(m, ffp);
    } else {
        fprintf(stderr, "%s: no streams in %s\n", __func__, fn);
        return -1;
    }
    
    return 0;
}

void media_destroy(Media *m) {
    Stream *streams = media_streams(m);
    for (int i = 0; i < media_nb_streams(m); i++) {
        stream_destroy(streams + i);
    }
    dict_destroy(media_info(m));
    free(media_info(m));
    free(media_streams(m));
    free(media_filename(m));
}