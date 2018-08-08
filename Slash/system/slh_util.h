//
//  slh_util.h
//  Slash
//
//  Created by Terminator on 2018/08/07.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#ifndef slh_util_h
#define slh_util_h

#include <stdio.h>

/**
 * Argument arrays manipulation.
 * To use with Process and Player objects.
 */

/**
 * Find number of items in an argument array.
 * 
 * @param args a NULL-terminated array of strings. This parameter cannot be NULL.
 *
 * @return Number of items in the array not counting the terminating NULL pointer. 
 */
size_t args_len(char *const *args);

/**
 * Copy the argument array src to dst including the terminating NULL pointer.
 *
 * @param dst allocated chunk of memory with enough space to hold contents of src
 *            this parameter cannot be NULL.
 *
 * @param src a NULL-terminated array of strings. This parameter cannot be NULL.
 *
 * @return dst
 */
char **args_cpy(char **dst, char *const *src);

/**
 * Add an item into an argument array.
 * 
 * @param args a pointer to a NULL-terminated array of strings. 
 *             this parameter cannot be NULL.
 *
 * @param str a NULL-terminated string. This parameter cannot be NULL.
 * 
 * @return args that contains str or NULL if realloc() fails. 
 */
char **args_add(char ***args, const char *str);

/**
 * Deallocate previously allocated array.
 *
 * @param args an allocated NULL-terminated array of strings. 
 *             This parameter cannot be NULL.
 */
void args_free(char **args);

#endif /* slh_util_h */
