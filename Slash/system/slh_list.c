//
//  slh_list.c
//  Slash
//
//  Created by Terminator on 2019/04/17.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#include "slh_list.h"

#pragma mark - Initialization / Destruction

void list_init(List *l, void (*destroy)(void *data)) {
    l->size = 0;
    l->destroy_f = destroy;
    l->head = NULL;
    l->tail = NULL;
}


