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

#pragma mark - insert

int list_insert_next(List *l, ListNode *node, const void *data) {
    ListNode *new_node = malloc(sizeof(ListNode));
    if (!new_node) {
        return -1;
    }
    
    new_node->data = (void *)data;
    
    if (!node) { // insert at the head of the list
        if (list_size(l) == 0) {
            l->tail = new_node;
        }
        new_node->next = l->head;
        l->head = new_node;
    } else {
        if (!node->next) {
            l->tail = new_node;
        }
        new_node->next = node->next;
        node->next = new_node;
    }
    
    l->size++;
    return 0;
}


#pragma mark - remove

int list_remove_next(List *l, ListNode *node, void **data) {
    if (list_size(l) == 0) { // the list must not be empty
        return -1;
    }
    
    ListNode *old_node;
    if (!node) { // remove from the head of the list
        *data = l->head->data;
        old_node = l->head;
        l->head = l->head->next;
        if (list_size(l) == 1) { // remove the last node
            l->tail = NULL;
        }
    } else {
        if (!node->next) { // cannot remove from the tail of the list
            return -1;
        }
        *data = node->next->data;
        old_node = node->next;
        node->next = node->next->next;
        
        if (!node->next) { // assign a new tail
            l->tail = node;
        }
    }
    
    free(old_node);
    l->size--;
    return 0;
}