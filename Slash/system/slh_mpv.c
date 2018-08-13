//
//  slh_mpv.c
//  Slash
//
//  Created by Terminator on 2018/07/27.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//
#include <stdlib.h>
#include <stdbool.h>
#include <errno.h>
#include <string.h>
#include <time.h>
#include <dispatch/dispatch.h>

#include "slh_mpv.h"
#include "slh_util.h"

static inline void plr_error(const char *s1, const char *s2) {
    fprintf(stderr, "%s : %s\n", s1, s2);
}

#pragma mark - Initialize

int plr_init(Player *p, char *const *args) {

    p->proc = malloc(sizeof(Process));
    char **ac = malloc((args_len(args) + 1) * sizeof(char *));
    args_cpy(ac, args);
    
    char *tmp, *cmd, *pth;
    
    asprintf(&pth, "/tmp/mpv_%lx", time(0));        // generate socket path name
    p->socket_path = pth;
    
    asprintf(&cmd, "%s --list-options | grep input-ipc-server", ac[0]);
    if (system(cmd)) {                              // check if mpv is outdated
        asprintf(&tmp, "--input-unix-socket=%s", pth);
    } else {
        asprintf(&tmp, "--input-ipc-server=%s", pth);
    }
    
    if(!args_add(&ac, tmp)) {
        plr_error(__func__, "Initialization failed");
        free(cmd);
        free(tmp);
        args_free(ac);
        free(pth);
        free(p->proc);
        return -1;
    };
    
    prc_init(p->proc, ac);
    p->soc = malloc(sizeof(Socket));
    p->cb = calloc(1, sizeof(PCallback));
    p->cb->func = (callback_f)fputs;
    p->cb->context = stdout;
    p->gr = dispatch_group_create();
    
    free(cmd);
    free(tmp);
    args_free(ac);
    return 0;
}

#pragma mark - Destroy

void plr_destroy(Player *p) {
    
    soc_shutdown(p->soc);
    free(p->soc);
    remove(p->socket_path);
    free(p->socket_path);
    
    if (prc_pid(p->proc) > 0) {
        prc_kill(p->proc);
    }
    dispatch_group_wait(p->gr, DISPATCH_TIME_FOREVER);
    dispatch_release(p->gr);
    prc_destroy(p->proc);
    free(p->proc);
    free(p->cb);
}

