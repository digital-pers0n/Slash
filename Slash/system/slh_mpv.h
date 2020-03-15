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
#include <pthread/pthread.h>
#include <stdatomic.h>

typedef void (*ipc_read_f)(ssize_t size, void *context);
typedef void (*callback_f)(char *data, void *context);
typedef void (*exit_f)(void *player, void *context);
typedef struct _PCallback {
    void *context;
    callback_f func;
    exit_f exit;
    ipc_read_f ipc_read;
} PCallback;

typedef struct _Player {
    Socket *soc;
    char *socket_path;
    Process *proc;
    atomic_int kq;          // kqueue
    PCallback *cb;
    void *gr;               // dispatch_group_t
    pthread_mutex_t lock;
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
 * Set a user-defined callback function. The function is called during media playback
 * 
 * @param context a user-defined context
 * @param func a custom function
 */

void plr_set_callback(Player *p, void *context, callback_f func);

/**
 * Set a user-defined function. The function is called when the player exited.
 *
 * @param func a custom function
 */

void plr_set_exit_cb(Player *p, exit_f func);


/**
 * Set a user-defined IPC function. 
 * The function is called when data can be read via @c plr_msg_recv().
 * 
 * @note This function is not thread-safe. It's unsafe to call it if the
 * @c plr_is_connected() returns 1. It should be called before @c plr_connect()
 *
 * @param func a pointer to a user-defined function or NULL.
 */

void plr_set_ipc_cb(Player *p, ipc_read_f func);

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
 * @return 0 on success. -1 if an error occurs.
 */

int plr_disconnect(Player *p);

/**
 * Check if the IPC connection is alive
 *
 * @return 1 if the conneciton is alive, 0 otherwise.
 */
int plr_is_connected(Player *p);

/**
 * Destroy and deinitialize the player.
 */ 

void plr_destroy(Player *p);

/**
 * Send a message to the player.
 * 
 * @param msg an array that contains a vaild mpv JSON IPC message.
 * @param len length of the message
 * @return On success the number of bytes which were sent is returned. Otherwise -1.
 */

ssize_t plr_msg_send(Player *p, const char *msg, size_t len);

/**
 * Receive a message from the player.
 *
 * @return the number of bytes received or -1 if an error occured.
 */

ssize_t plr_msg_recv(Player *p, char *buffer, size_t len);

#endif /* slh_mpv_h */
