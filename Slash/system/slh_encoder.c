//
//  slh_encoder.c
//  Slash
//
//  Created by Terminator on 2018/11/05.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#include "slh_encoder.h"
#include "slh_util.h"
#include <stdlib.h>
#include <signal.h>
#include <dispatch/dispatch.h>

#pragma mark - Init

int encoder_init(Encoder *enc, char *const *args) {
    if ((enc->proc = malloc(sizeof(Process))) == NULL) {
        return -1;
    }
    prc_init(enc->proc, args);
    enc->gr = dispatch_group_create();
    return 0;
}

void encoder_set_args(Encoder *enc, char *const *args) {
    prc_set_args(enc->proc, args);
}

#pragma mark - Destroy

void encoder_destroy(Encoder *enc) {
    if (prc_pid(enc->proc) > 0) {
        prc_kill(enc->proc);
    }
    dispatch_group_wait(enc->gr, DISPATCH_TIME_FOREVER);
    dispatch_release(enc->gr);
    prc_destroy(enc->proc);
    free(enc->proc);
}

#pragma mark - Start / stop encoding

static void encoder_read_output(FILE *fp, encoder_callback_f func, void *ctx) {
    static const size_t kLen = ENCODER_BUFFER_SIZE;
    char *buffer = malloc(kLen * sizeof(char));
    
    while (fgets(buffer, kLen, fp)) {
        func(buffer, ctx);
    }
    free(buffer);
}

int encoder_start(Encoder *enc, encoder_callback_f out_f, encoder_exit_f exit_f, void *ctx) {
    if (prc_does_exist(enc->proc) == 0) {
        fprintf(stderr, "%s: encoding in progress\n", __func__);
        return -1;
    }
    
    if (prc_launch(enc->proc) != 0) {
        fprintf(stderr, "%s: failed to start encoding\n", __func__);
        return -1;
    }
    
    dispatch_queue_t gq = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_group_async(enc->gr, gq, ^{
        
        dispatch_group_enter(enc->gr);
        
        dispatch_group_async(enc->gr, gq, ^ {
            
            dispatch_group_enter(enc->gr);
            encoder_read_output(prc_stdout(enc->proc), out_f, ctx);
            dispatch_group_leave(enc->gr);
            
        });
            
        encoder_read_output(prc_stderr(enc->proc), out_f, ctx);
        
        int exit_code = -1;
        if (prc_pid(enc->proc) > 0) { // otherwise the process was previously killed by the encoder_stop() function
            
            exit_code = prc_close(enc->proc);
        }
        if (exit_f) {
            exit_f(ctx, exit_code);
        }
        
        dispatch_group_leave(enc->gr);
        
    });
    
    dispatch_release(gq);
    return 0;
}

int encoder_start_old(Encoder *enc, encoder_callback_f func, void *ctx) {
    if (prc_does_exist(enc->proc) == 0) {
        fprintf(stderr, "%s: encoding in progress\n", __func__);
        return -1;
    }
    
    if (prc_launch(enc->proc) != 0) {
        fprintf(stderr, "%s: failed to start encoding\n", __func__);
        return -1;
    }
    
    if (!func) {
        func = (encoder_callback_f)fputs;
        ctx = stdout;
    }
    
    dispatch_queue_t gq = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_group_async(enc->gr, gq, ^{
        
        dispatch_group_enter(enc->gr);
        
        dispatch_group_async(enc->gr, gq, ^ {
            
            dispatch_group_enter(enc->gr);
            encoder_read_output(prc_stderr(enc->proc), func, ctx);
            dispatch_group_leave(enc->gr);
            
        });
        
        encoder_read_output(prc_stdout(enc->proc), func, ctx);
        prc_close(enc->proc);
        dispatch_group_leave(enc->gr);
        dispatch_release(gq);
        
    });
    
    return 0;
}

int encoder_stop(Encoder *enc) {
    if (prc_pid(enc->proc) > 0) {
        return prc_kill(enc->proc);
    }
    return -1;
}

int encoder_pause(Encoder *enc, bool value) {
    pid_t pid = prc_pid(enc->proc);
    if (pid > 0) {
        int signal = (value) ? SIGSTOP : SIGCONT;
        return kill(pid, signal);
    }
    return -1;
}