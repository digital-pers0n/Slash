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

/* Initialization / Destruction */
void prc_init(Process *p, char **args);

void prc_destroy(Process *p);

/* Launch a process and create stderr/stdout pipes. */
int prc_launch(Process *p);

/* Wait for the associated process to terminate, and return exit code. */
int prc_close(Process *p);

/* Kill the associated process. */
int prc_kill(Process *p);

/* Check if the associated process exists */
int prc_does_exist(Process *p);

/* Accessors */

static inline FILE *prc_stdout(Process *p) {
    return p->std_out;
}

static inline FILE *prc_stderr(Process *p) {
    return p->std_err;
}

static inline pid_t prc_pid(Process *p) {
    return p->pid;
}

static inline char **prc_args(Process *p) {
    return p->args;
}

#endif /* slh_process_h */
