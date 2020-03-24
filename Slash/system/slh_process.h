//
//  slh_process.h
//  Slash
//
//  Created by Terminator on 2018/07/23.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#ifndef slh_process_h
#define slh_process_h

#include <stdio.h>
#include <stdbool.h>
#include <spawn.h>


typedef struct _Process {
    char **args;            // a NULL-terminated array of pointers to NULL-terminated strings
    FILE *std_err;
    FILE *std_out;
    pid_t pid;
    posix_spawn_file_actions_t fa;
} Process;

/**
 * Initialize a process.
 *
 * @param args a NULL-terminated array of pointers to NULL-terminated strings
 *             args[0] must contain a path to an executable file.
 *             This parameter cannot be NULL.
 */
void prc_init(Process *p, char *const *args);

/**
 * Destroy the process.
 */
void prc_destroy(Process *p);

/**
 * Same as @c prc_init() but doesn't make a copy of @c args.
 * You have to destroy the process with @c prc_destroy_no_copy() after.
 */
void prc_init_no_copy(Process *p, char *const *args);

/**
 * Destroy the process.
 * Use this instead of @c prc_destroy() if you init the process
 * with @c prc_init_no_copy()
 */
void prc_destroy_no_copy(Process *p);

/** 
 * Launch the process and create stderr/stdout pipes. 
 *
 * @return 0 on success, -1 otherwise.
 */
int prc_launch(Process *p);

/**
 * Wait for the associated process to terminate.
 *
 * @return exit code of the process.
 */
int prc_close(Process *p);

/** 
 * Kill the associated process. 
 *
 * @return 0 on success, -1 otherwise.
 */
int prc_kill(Process *p);

/**
 *  Check if the associated process exists.
 *
 *  @return 0 if the process is active.
 */
int prc_does_exist(Process *p);

/* Accessors */

/**
 * Get the stdout pipe.
 *
 * @return stdout pipe or NULL.
 */
static inline FILE *prc_stdout(Process *p) {
    return p->std_out;
}

/**
 * Get the stderr pipe.
 *
 * @return stderr pipe or NULL.
 */
static inline FILE *prc_stderr(Process *p) {
    return p->std_err;
}

/**
 * Get the pid value of the running process.
 *
 * @return pid value or -1 if the process is not running.
 */ 
static inline pid_t prc_pid(Process *p) {
    return p->pid;
}

/**
 * Set an array of arguments.
 *
 * @param args a NULL-terminated array of pointers to NULL-terminated strings
 *             args[0] must contain a path to an executable file.
 *             This parameter cannot be NULL.
 */
void prc_set_args(Process *p, char *const *args);

/**
 * Get the arguments array.
 *
 * @return arguments array.
 */
static inline char **prc_args(Process *p) {
    return p->args;
}

#endif /* slh_process_h */
