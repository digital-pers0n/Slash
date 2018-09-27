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

#pragma mark - Add / Replace / Remove Key-Values

static int dict_rehash(Dictionary *t) {
    size_t new_pos = (t->positions << 1) + 1;
    KeyVal *new_table = calloc(new_pos, sizeof(KeyVal));
    if (!new_table) {
        return -1;
    }
    
    for (size_t i = 0; i < t->positions; i++) {
        KeyVal *old_kv = &t->table[i];
        if (old_kv->key && old_kv->key != t->vacated) {
            uint64_t hv = hash(old_kv->key);
            for (size_t j = 0; j < new_pos; j++) {
                size_t new_idx = (hv + j) % new_pos;
                KeyVal *new_kv = &new_table[new_idx];
                if (new_kv->key == NULL) {
                    new_kv->key = old_kv->key;
                    new_kv->value = old_kv->value;
                    break;
                }
            }
        }
    }
    free(t->table);
    t->table = new_table;
    t->positions = new_pos;
    return 0;
}

/**
 Find the key-value pair associated with the given key.
 
 @return NULL if the key-vale pair doesn't exist.
 */

static KeyVal *dict_get_keyval(Dictionary *t, const char *key, uint64_t hv) {
    for (size_t i = 0; i < t->positions; i++) {
        size_t idx = (hv + i) % t->positions;
        KeyVal *kv = &t->table[idx];
        if (kv->key == NULL) {
            return NULL;
        } else if (kv->key == t->vacated) {
            continue;
        } else if (strcmp(kv->key, key) == 0) {
            return kv;
        }
    }
    
    /* Nothing is found */
    return NULL;
}



int dict_add_value(Dictionary *t, const char *key, const void *value) {
    uint64_t hv = hash(key);
    if (dict_get_keyval(t, key, hv) != NULL) {
        return -1;
    }
    
    if ((double)t->size / t->positions > 0.75) {
        if (dict_rehash(t) !=  0) {
            return -2;
        }
    }
    
    for (size_t i = 0; i < t->positions; i++) {
        size_t idx = (hv + i) % t->positions;
        KeyVal *kv = &t->table[idx];
        if (kv->key == NULL || kv->key == t->vacated) {
            kv->key = strdup(key);
            kv->value = (void *)value;
            t->size++;
            return 0;
        }
    }

    return -1;
}

int dict_replace_value(Dictionary *t, const char *key, const void *new_value, void **old_value) {
    uint64_t hv = hash(key);
    KeyVal *kv = dict_get_keyval(t, key, hv);
    if (!kv) {
        return -1;
    }
    if (old_value) {
        *old_value = kv->value;
    }
    kv->value = (void *)new_value;
    return 0;
}

int dict_remove_value(Dictionary *t, const char *key, void **value) {
    uint64_t hv = hash(key);
    KeyVal *kv = dict_get_keyval(t, key, hv);
    if (!kv) {
        return -1;
    }
    free(kv->key);
    kv->key = t->vacated;
    if (value) {
        *value = kv->value;
    }
    kv->value = NULL;
    t->size--;
    return 0;
}

void dict_remove_all(Dictionary *t) {
    for (size_t i = 0; i < t->positions; i++) {
        KeyVal *kv = &t->table[i];
        if (kv->key == t->vacated) {
            kv->key = NULL;
        } else if (kv->key != NULL) {
            free(kv->key);
            kv->key = NULL;
            if (t->destroy) {
                t->destroy(kv->value);
                kv->value = NULL;
            }
            t->size--;
        }
        
    }
}

void *dict_get_value(Dictionary *t, const char *key) {
    uint64_t hv = hash(key);
    KeyVal *kv = dict_get_keyval(t, key, hv);
    if (!kv) {
        return NULL;
    }
    return kv->value;
}

static void dict_get_keys(Dictionary *t, char **keys) {
    for (size_t i = 0, j = 0; i < t->positions; i++) {
        KeyVal *kv = &t->table[i];
        if (kv->key && kv->key != t->vacated) {
            keys[j++] = kv->key;
        }
    }
}
static void dict_get_values(Dictionary *t, void **values) {
    for (size_t i = 0, j = 0; i < t->positions; i++) {
        KeyVal *kv = &t->table[i];
        if (kv->key && kv->key != t->vacated) {
            values[j++] = kv->value;
        }
    }
}

static void dict_get_keyvals(Dictionary *t, char **keys, void **values) {
    for (size_t i = 0, j = 0; i < t->positions; i++) {
        KeyVal *kv = &t->table[i];
        if (kv->key && kv->key != t->vacated) {
            keys[j] = kv->key;
            values[j++] = kv->value;
        }
    }
}

void dict_get_keys_and_values(Dictionary *t, char **keys, void **values) {
    
    if (keys && values) {
        dict_get_keyvals(t, keys, values);
    } else {
        if (keys) {
            dict_get_keys(t, keys);
        }
        if (values) {
            dict_get_values(t, values);
        }
    }

}