//
//  MPVBase.h
//  Slash
//
//  Created by Terminator on 2019/10/12.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#ifndef MPVBase_h
#define MPVBase_h

#import <mpv/client.h>

#define func_attributes __attribute__((overloadable, always_inline))

#pragma mark - mpv functions

static inline void mpv_print_log_message(struct mpv_event_log_message *msg) {
    printf("[%s]  %s : %s", msg->prefix, msg->level, msg->text);
}

#pragma mark set/get mpv properties

/**
 Set @c char string.
 */
func_attributes static int  mpv_set_value_for_key(mpv_handle *mpv, const char *value, const char *key) {
    mpv_node node = {
        .u.string = (char *)value,
        .format = MPV_FORMAT_STRING
    };
    return mpv_set_property(mpv, key, MPV_FORMAT_NODE, &node);
}

/**
 Set @c int flag.
 */
func_attributes static int  mpv_set_value_for_key(mpv_handle *mpv, int value, const char *key) {
    mpv_node node = {
        .u.flag = value,
        .format = MPV_FORMAT_FLAG
    };
    return mpv_set_property(mpv, key, MPV_FORMAT_NODE, &node);
}

/**
 Set @c int64_t value.
 */
func_attributes static int  mpv_set_value_for_key(mpv_handle *mpv, int64_t value, const char *key) {
    mpv_node node = {
        .u.int64 = value,
        .format = MPV_FORMAT_INT64
    };
    return mpv_set_property(mpv, key, MPV_FORMAT_NODE, &node);
}

/**
 Set @c double value.
 */
func_attributes static int  mpv_set_value_for_key(mpv_handle *mpv, double value, const char *key) {
    mpv_node node = {
        .u.double_ = value,
        .format = MPV_FORMAT_DOUBLE
    };
    return mpv_set_property(mpv, key, MPV_FORMAT_NODE, &node);
}

/**
 Get @c char string. Free @c value with @c mpv_free() to avoid memory leaks.
 */
func_attributes static int  mpv_get_value_for_key(mpv_handle *mpv, char **value, const char *key) {
    return mpv_get_property(mpv, key, MPV_FORMAT_STRING, value);
}

/**
 Get @c int flag.
 */
func_attributes static int  mpv_get_value_for_key(mpv_handle *mpv, int *value, const char *key) {
    return mpv_get_property(mpv, key, MPV_FORMAT_FLAG, value);
}

/**
 Get @c int64_t value.
 */
func_attributes static int  mpv_get_value_for_key(mpv_handle *mpv, int64_t *value, const char *key) {
    return mpv_get_property(mpv, key, MPV_FORMAT_INT64, value);
}

/**
 Get @c double value.
 */
func_attributes static int  mpv_get_value_for_key(mpv_handle *mpv, double *value, const char *key) {
    return mpv_get_property(mpv, key, MPV_FORMAT_DOUBLE, value);
}

#pragma mark mpv commands

func_attributes static int  mpv_perform_command_with_arguments(mpv_handle *mpv, const char *command, const char *arg1, const char *arg2, const char *arg3) {
    const char *cmd[] = { command, arg1, arg2, arg3, NULL };
    return mpv_command(mpv, cmd);
}

func_attributes static int  mpv_perform_command_with_arguments(mpv_handle *mpv, const char *command, const char *arg1, const char *arg2) {
    const char *cmd[] = { command, arg1, arg2, NULL };
    return mpv_command(mpv, cmd);
}

func_attributes static int  mpv_perform_command_with_argument(mpv_handle *mpv, const char *command, const char *arg1) {
    const char *cmd[] = { command, arg1, NULL };
    return mpv_command(mpv, cmd);
}

func_attributes static int  mpv_perform_command(mpv_handle *mpv, const char *command) {
    const char *cmd[] = { command, NULL };
    return mpv_command(mpv, cmd);
}

#endif /* MPVBase_h */
