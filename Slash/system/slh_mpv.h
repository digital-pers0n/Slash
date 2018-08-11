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
    Socket *soc;
    char *socket_path;
    Process *proc;
    PCallback *cb;
} Player;

/**
 * Initialize a player.
 * 
 * @param args a NULL-terminated array of pointers to NULL-terminated strings
 *             The array should contain valid mpv options.
 *             args[0] must contain the file path to mpv executable.
 * @return Upon successful initialization 0 is returned, otherwise, -1
 */
 
int plr_init(Player *p, char *const *args);

/**
 * Set a user-defined callback function
 * 
 * @param context a user-defined context
 * @param func a custom function
 */

void plr_set_callback(Player *p, void *context, callback_f func);

/**
 * Launch the player.
 * 
 * @return 0 on success. -1 if an error occurs.
 */

int plr_launch(Player *p);

/**
 * Initialize an IPC connection. Can be called after plr_launch()
 *
 * @return 0 on succes. -1 if an error occurs.
 */

int plr_connect(Player *p);

/**
 * Close the IPC connection. 
 *
 * @return 0 on succes. -1 if an error occurs.
 */

int plr_disconnect(Player *p);

/**
 * Destroy and deinitialize the player.
 */ 

void plr_destroy(Player *p);

/**
 * Send a message to the player.
 * 
 * @param msg an array that contains a vaild mpv JSON IPC message.
 * @return On success the number of bytes which were sent is returned. Otherwise -1.
 */

ssize_t plr_msg_send(Player *p, char *msg);

#endif /* slh_mpv_h */
