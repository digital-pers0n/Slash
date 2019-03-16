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

static void _dummy_exit_cb(void *p, void *ctx) { return; }

static inline void plr_error(const char *s1, const char *s2) {
    fprintf(stderr, "%s : %s\n", s1, s2);
}

#pragma mark - Initialize

int plr_init(Player *p, char *const *args) {

    p->proc = malloc(sizeof(Process));
    char **ac = args_init((args_len(args) + 1));
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
    p->cb->exit = _dummy_exit_cb;
    p->gr = dispatch_group_create();
    
    free(cmd);
    free(tmp);
    args_free(ac);
    return 0;
}

void plr_set_callback(Player *p, void *ctx, callback_f func) {
    if (!func) {
        p->cb->func = (callback_f)fputs;
        p->cb->context = stdout;
    } else {
        p->cb->func = func;
        p->cb->context = ctx;
    }
}

void plr_set_exit_cb(Player *p, exit_f func) {
    p->cb->exit = (func) ? func : _dummy_exit_cb;
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

#pragma mark - Launch

static void plr_read_output(FILE *fp, PCallback *cb) {
    
    const int len = 128;
    char *buffer = malloc(len * sizeof(char));
    while(fgets(buffer, len, fp)) {
        cb->func(buffer, cb->context);
    }
    free(buffer);
}

int plr_launch(Player *p) {
    
    if (prc_does_exist(p->proc) == 0) {
        plr_error(__func__, "mpv is already running");
        return -1;
    }
    if (prc_launch(p->proc) != 0) {
        plr_error(__func__, "failed to launch");
        return -1;
    }
    
    /* Read output */
    dispatch_queue_t gq = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_async(p->gr, gq, ^{
        
        dispatch_retain(p->gr);
        dispatch_group_enter(p->gr);
        
        dispatch_group_async(p->gr, gq, ^{
            
            dispatch_group_enter(p->gr);
            
            plr_read_output(prc_stderr(p->proc), p->cb);
            
            dispatch_group_leave(p->gr);
            
        });
        
        plr_read_output(prc_stdout(p->proc), p->cb);
        prc_close(p->proc);
        
        dispatch_group_leave(p->gr);
        dispatch_release(gq);
        p->cb->exit(p, p->cb->context);
        
    });

    return 0;
}

#pragma mark - IPC

int plr_connect(Player *p) {
    if (soc_connect(p->soc, p->socket_path) != 0) {
        plr_error(__func__, "Connection failed");
        return -1;
    }
    return 0;
}

int plr_disconnect(Player *p) {
    if (soc_shutdown(p->soc) != 0) {
        plr_error(__func__, "Operation failed");
        return -1;
    }
    return 0;
}

ssize_t plr_msg_send(Player *p, const char *msg) {
    return soc_send(p->soc, msg, strlen(msg));
}

ssize_t plr_msg_recv(Player *p, char *buf, size_t len) {
    return soc_recv(p->soc, buf, len);
}
