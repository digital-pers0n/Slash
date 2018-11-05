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

int encoder_init(Encoder *enc, char *const *args);
void encoder_destroy(Encoder *enc);
int encoder_start(Encoder *enc, encoder_callback_f func, void *ctx);
int encoder_stop(Encoder *enc);

#endif /* slh_encoder_h */
