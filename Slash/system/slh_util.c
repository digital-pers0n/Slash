//
//  slh_util.c
//  Slash
//
//  Created by Terminator on 2018/08/07.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#include "slh_util.h"
#include <stdlib.h>
#include <string.h>
#include <errno.h>


size_t args_len(char *const *in) {
    size_t len = 0;
    while (*(in++) != NULL) {
        len++;
    }
    return len;
}

char **args_cpy(char **dst, char *const *src) {
    size_t len = 0;
    while (*src != NULL) {
        dst[len++] = strdup(*(src++));
    }
    dst[len] = NULL;
    return dst;
}

char **args_add(char *** args, const char *str) {
    size_t len = args_len(*args);
    (*args)[len] = strdup(str);
    len++;
    char **tmp;
    if (!(tmp = realloc(*args, (len + 1) * sizeof(char *)))) {
        
        fprintf(stderr, "%s : realloc() : %i %s\n", __func__, errno, strerror(errno));
        return NULL;
    }
    *args = tmp;
    (*args)[len] = NULL;
    return *args;
}

void args_free(char **args) {
    char **ptr = args;
    while (*ptr != NULL) {
        free(*(ptr++));
    }
    free(args);
}

