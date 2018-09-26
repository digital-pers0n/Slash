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

