//
//  slh_process.c
//  Slash
//
//  Created by Terminator on 2018/07/23.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#include "slh_process.h"
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/wait.h>
#include <spawn.h>
#include <stdbool.h>
#include <errno.h>
#include <signal.h>

#pragma mark - Initialization

void prc_init(Process *p, char **args) {
    p->args = args;
    p->pid = -1;
    p->std_err = NULL;
    p->std_out = NULL;
    p->fa = NULL;
}

#pragma mark - Destruction

void prc_destroy(Process *p) {
    if (prc_pid(p) > 0) {
        prc_close(p);
    }
    p->args = NULL;
}