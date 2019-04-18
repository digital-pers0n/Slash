//
//  slh_list.c
//  Slash
//
//  Created by Terminator on 2019/04/17.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#include <stdlib.h>
#include "slh_list.h"

#pragma mark - Initialization / Destruction

void list_init(List *l, void (*destroy)(void *data)) {
    l->size = 0;
    l->destroy_f = destroy;
    l->head = NULL;
    l->tail = NULL;
}

static inline void _list_free_data(List *l) {
    while (list_size(l) > 0) {
        l->destroy_f(l->head->data);
        ListNode *old_node = l->head;
        l->head = l->head->next;
        free(old_node);
        l->size--;
    }
}

static inline void _list_no_free(List *l) {
    while (list_size(l) > 0) {
        ListNode *old_node = l->head;
        l->head = l->head->next;
        free(old_node);
        l->size--;
    }
}

void list_destroy(List *l) {
    if (l->destroy_f == NULL) {
        _list_no_free(l);
    } else {
        _list_free_data(l);
    }
}
