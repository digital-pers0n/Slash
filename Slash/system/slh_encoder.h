//
//  slh_encoder.h
//  Slash
//
//  Created by Terminator on 2018/11/05.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#ifndef slh_encoder_h
#define slh_encoder_h

#include <stdio.h>
#include "slh_process.h"

#define ENCODER_BUFFER_SIZE 128

typedef void (*encoder_callback_f)(char *data, void *context, ssize_t data_len);
typedef void (*encoder_exit_f)(void *context, int exit_code);

typedef struct _Encoder {
    Process *proc;
    void *gr;           // dispatch_group
} Encoder;

/**
 * Initialize an encoder.
 *
 * @param args a NULL-terminated array of pointers to NULL-terminated strings
 *             args[0] must contain file path to ffmpeg executable.
 *             This parameter cannot be NULL.
 *
 * @return 0 on success, -1 otherwise.
 */
int encoder_init(Encoder *enc, char *const *args);

/**
 * Destroy the encoder.
 */
void encoder_destroy(Encoder *enc);

/**
 * Set encoding arguments.
 *
 * @param args a NULL-terminated array of pointers to NULL-terminated strings
 *             args[0] must contain file path to ffmpeg executable.
 *             This parameter cannot be NULL.
 */

void encoder_set_args(Encoder *enc, char *const *args);

/**
 * Start encoding.
 *
 * @param output Pointer to a function that can be used to read message log of the encoder. 
 *               This parameter cannot be NULL. 
 *
 * @param exit Pointer to a function that will be called when the encoding process is finished. 
 *             It's an optional argument.
 *
 * @param ctx Optional pointier to a user-defined context.
 *
 * @return 0 on success, -1 otherwise.
 */
int encoder_start(Encoder *enc, encoder_callback_f output, encoder_exit_f exit, void *ctx);

/**
 * Stop encoding.
 *
 * @return 0 on success, -1 otherwise.
 */
int encoder_stop(Encoder *enc);

/**
 * Pause or resume the encoder.
 *
 * @param value YES pause the encoding process, NO resume it. 
 *
 * @return 0 on success, -1 if error occurs.
 */
int encoder_pause(Encoder *enc, bool value);

#endif /* slh_encoder_h */
