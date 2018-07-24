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


#endif /* slh_process_h */
