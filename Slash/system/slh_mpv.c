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
#include <pthread/pthread_spis.h>
#include <sys/event.h>

#include "slh_mpv.h"
#include "slh_util.h"

static void _dummy_exit_cb(void *p, void *ctx) { return; }
static void _dummy_ipc_cb(ssize_t size, void *ctx) { return; }

static inline void plr_error(const char *s1, const char *s2) {
    fprintf(stderr, "%s : %s\n", s1, s2);
}

static inline char *_get_tmp_dir() {
    extern char *g_temp_dir;
    return (g_temp_dir) ? g_temp_dir : "/tmp";
}

static inline int plr_kqueue(Player *p) {
    return atomic_load(&p->kq);
}

static inline void plr_set_kqueue(Player *p, int kq) {
    atomic_store(&p->kq, kq);
}

#pragma mark - Initialize

int plr_init(Player *p, char *const *args) {

    p->proc = malloc(sizeof(Process));
    char **ac = args_init((args_len(args) + 1));
    args_cpy(ac, args);
    
    char *tmp, *cmd, *pth;
    
    asprintf(&pth, "%s/mpv_%lx", _get_tmp_dir(), time(0));        // generate socket path name
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
    p->cb->ipc_read = _dummy_ipc_cb;
    p->gr = dispatch_group_create();
    
    pthread_mutexattr_t mattr;
    pthread_mutexattr_init(&mattr);
    pthread_mutexattr_setpolicy_np(&mattr, _PTHREAD_MUTEX_POLICY_FIRSTFIT);
    pthread_mutex_init(&p->lock, &mattr);
    
    p->kq = -1;
    
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

void plr_set_ipc_cb(Player *p, ipc_read_f func) {
    p->cb->ipc_read = (func) ? func : _dummy_ipc_cb;
}

#pragma mark - Destroy

void plr_destroy(Player *p) {
    if (plr_is_connected(p)) {
        const char cmd[] = "{ \"command\": [\"quit\"] }\n";
        plr_msg_send(p, cmd, sizeof(cmd) - 1);
        soc_shutdown(p->soc);
    }
    free(p->soc);
    unlink(p->socket_path);
    free(p->socket_path);
    
    pthread_mutex_lock(&p->lock);
    if (prc_pid(p->proc) > 0) {
        prc_kill(p->proc);
    }
    pthread_mutex_unlock(&p->lock);
    
    dispatch_group_wait(p->gr, DISPATCH_TIME_FOREVER);
    dispatch_release(p->gr);
    prc_destroy(p->proc);
    free(p->proc);
    free(p->cb);
    pthread_mutex_destroy(&p->lock);
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
        
        pthread_mutex_lock(&p->lock);
        if (prc_pid(p->proc) > 0) {
            prc_close(p->proc);
        }
        pthread_mutex_unlock(&p->lock);
        
        dispatch_group_leave(p->gr);
        dispatch_release(gq);
        p->cb->exit(p, p->cb->context);
        
    });

    return 0;
}

#pragma mark - IPC

int plr_connect(Player *p) {
    
    int kq = plr_kqueue(p);
    if (kq > -1) {
        plr_error(__func__, "Already connected");
        return -1;
    }
    if (soc_connect(p->soc, p->socket_path) != 0) {
        plr_error(__func__, "Connection failed");
        return -1;
    }

    if (fcntl(*p->soc, F_SETFL, O_NONBLOCK)) {
        plr_error("Cannot set socket to non-blocking mode", strerror(errno));
    }
    kq = kqueue();
    if (kq == -1) {
        plr_error("Cannot open kqueue", strerror(errno));
        return -1;
    }
    plr_set_kqueue(p, kq);
    
    dispatch_queue_t q = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0);
    dispatch_async(q, ^{
        
        struct kevent ke;
        EV_SET(&ke,
               *p->soc,
               EVFILT_READ,
               EV_ADD | EV_ENABLE | EV_CLEAR, 0, 0, NULL);
        
        if (kevent(kq, &ke, 1, NULL, 0, NULL) == -1) {
            plr_error("Cannot create kevent", strerror(errno));
            goto done;
        };
        
        while (1) {
            
            if (kevent(kq, NULL, 0, &ke, 1, NULL) == -1) {
                plr_error("Cannot get kevent data", strerror(errno));
                goto done;
            }
            
            if (ke.flags & EV_EOF) {
                goto done;
            }
            ssize_t size = ke.data;
            p->cb->ipc_read(size, p->cb->context);
        }
        
    done:
        
        close(kq);
        plr_set_kqueue(p, -1);
        
    });
    dispatch_release(q);
    return 0;
}

int plr_disconnect(Player *p) {
    if (soc_shutdown(p->soc) != 0) {
        plr_error(__func__, "Operation failed");
        return -1;
    }
    return 0;
}

int plr_is_connected(Player *p) {
    if (plr_kqueue(p) == -1) {
        return 0;
    }
    return 1;
}

ssize_t plr_msg_send(Player *p, const char *msg, size_t len) {
    return soc_send(p->soc, msg, len);
}

ssize_t plr_msg_recv(Player *p, char *buf, size_t len) {
    return soc_recv(p->soc, buf, len);
}
