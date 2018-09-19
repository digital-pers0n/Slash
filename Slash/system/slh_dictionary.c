//
//  slh_dictionary.c
//  Slash
//
//  Created by Terminator on 9/17/18.
//  Copyright © 2018 digital-pers0n. All rights reserved.
//

#include <stdlib.h>
#include <string.h>
#include "slh_dictionary.h"

static const size_t kPos = 39;
static char vacated;

/* Dan J. Bernstein string hash */
static inline uint64_t hash(const char *str) {
    uint64_t h = 5381;
    while (*str) {
        // h = 33 * h + *str++;
        h = (h << 5) + h + *str++;
    }
    return h;
}

#pragma mark - Initialize / Destroy

int dict_init(Dictionary *t, destroy_f destroy) {
    if ((t->table = (KeyVal *)calloc(kPos, sizeof(KeyVal))) == NULL) {
        return -1;
    }
    t->size = 0;
    t->positions = kPos;
    t->vacated = &vacated;
    t->destroy = destroy;
    return 0;
}

static void dict_destroy_values(Dictionary *t) {
    for (size_t i = 0; i < t->positions; i++) {
        KeyVal *kv = &t->table[i];
        if (kv->value != NULL) {
            t->destroy(kv->value);
        }
        if (kv->key != t->vacated) {
            free(kv->key);
        }
    }
}

void dict_destroy(Dictionary *t) {
    if (t->destroy) {
        dict_destroy_values(t);
    } else {
        for (size_t i = 0; i < t->positions; i++) {
            KeyVal *kv = &t->table[i];
            if (kv->key != t->vacated) {
                free(kv->key);
            }
        }
    }
    free(t->table);
}