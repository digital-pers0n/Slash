//
//  slh_mpv.h
//  Slash
//
//  Created by Terminator on 2018/07/27.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#ifndef slh_mpv_h
#define slh_mpv_h

#include <stdio.h>
#include "slh_socket.h"
#include "slh_process.h"

typedef void (*callback_f)(void *player, void *context, char *data);
typedef struct _PCallback {
    void *context;
    callback_f func;
} PCallback;

typedef struct _Player {
    char *mpv_path;
    Socket *soc;
    char *socket_path;
    Process *proc;
    PCallback *cb;
} Player;

#endif /* slh_mpv_h */
