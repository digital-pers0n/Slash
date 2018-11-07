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

typedef void (*encoder_callback_f)(char *data, void *context);

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
 * Start encoding.
 *
 * @param func Optional user-defined funciton.
 *
 * @param ctx Optional pointier to a user-defined context.
 *
 * @return 0 on success, -1 otherwise.
 */
int encoder_start(Encoder *enc, encoder_callback_f func, void *ctx);

/**
 * Stop encoding.
 *
 * @return 0 on success, -1 otherwise.
 */
int encoder_stop(Encoder *enc);

#endif /* slh_encoder_h */
