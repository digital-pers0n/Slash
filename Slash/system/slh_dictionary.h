//
//  slh_dictionary.h
//  Slash
//
//  Created by Terminator on 9/17/18.
//  Copyright © 2018 digital-pers0n. All rights reserved.
//

/**
 * @header Dictionary
 * An open-addressed hashtable implemented as dictionary 
 */

#ifndef slh_dictionary_h
#define slh_dictionary_h

#include <stdio.h>

typedef void (*destroy_f)(void *);

typedef struct _KeyVal {
    char *key;
    void *value;
} KeyVal;

typedef struct _Dictionary {
    size_t positions;   // number of total positions
    size_t size;        // number of inserted key-value pairs in the dictionary
    void *vacated;      // dummy pointer is used to mark previously removed key-value pairs
    destroy_f destroy;  // user defined function to free memory used by values
    KeyVal *table;      // array of key-value pairs
} Dictionary;

/**
 * Initialize a dictionary.
 *
 * @param destroy   optional user-defined function which can be used 
 *                  to deallocate inserted values when dict_destroy() is called. 
 * @return 0 on success, otherwise -1
 */

int dict_init(Dictionary *t, destroy_f destroy);

/** 
 * Destroy the dictionary.
 */

void dict_destroy(Dictionary *t);

/**
 * Add the key-value pair to the dictionary.
 * The key is added only if no such key exists in the dictionary.
 * 
 * @param key   The key of the value. The key is copied by the dictionary. 
 *              This parameter cannot be NULL.
 * 
 * @param value The value to add into the dictionary.
 *
 * @return 0 on success, -1 if key exists in the dictionary, -2 if error occurs.
 */

int dict_add_value(Dictionary *t, const char *key, const void *value);

/**
 * Replace the value of the key in the dictionary
 * The value is replaced only if the key exists in the dictionary.
 *
 * @param key   The key of the value. This parameter cannot be NULL.
 *              
 * @param new_value The value to replace into the dictionary.
 *
 * @param old_value Upon return points to the value which was replaced.
 *
 * @return 0 on success, -1 if key doesn't exist in the dictionary
 */

int dict_replace_value(Dictionary *t, const char *key, const void *new_value, void **old_value);

/**
 * Remove the key-value pair from the dictionary. 
 * The value is removed only if the key exists in the dictionary.
 *
 * @param key   The key of the value. This parameter cannot be NULL
 *
 * @param value Upon return points to the value 
 *              which was removed from the dictionary.
 * 
 * @return 0 on success, -1 if no such key exists in the dictionary
 */

int dict_remove_value(Dictionary *t, const char *key, void **value);

/**
 * Remove all the key-values pairs from the dictionary.
 */

void dict_remove_all(Dictionary *t);

/**
 * Get the value associated with the provied key.
 *
 * @param key   They key of the value. This parameter cannot be NULL.
 * 
 * @return  The value associated with the given key in the dictionary,
 *          or NULL if no such key exists in the dictionary.
 */

void *dict_get_value(Dictionary *t, const char *key);

/**
 * Fill the two provided buffers with the keys and values from the dictionary.
 * The buffers must have enough space to hold at least dict_size() number of pointers.
 * 
 * @param keys  Upon return, filled with the keys from the dictionary. 
 *              This parameter can be NULL.
 *
 * @param values Upon return, filled with the values from the dictionary.
 *               This parameter can be NULL.
 *
 */
void dict_get_keys_and_values(Dictionary *t, char **keys, void **values);

/**
 * Return the number of key-value pairs currently in the dictionary.
 */

static inline size_t dict_size(Dictionary *t) {
    return t->size;
}

#endif /* slh_dictionary_h */
