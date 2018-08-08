//
//  slh_util.c
//  Slash
//
//  Created by Terminator on 2018/08/07.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#include "slh_util.h"

size_t args_len(char *const *in) {
    size_t len = 0;
    while (*(in++) != NULL) {
        len++;
    }
    return len;
}