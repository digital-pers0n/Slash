//
//  slh_list.h
//  Slash
//
//  Created by Terminator on 2019/04/17.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#ifndef slh_list_h
#define slh_list_h

#include <stdio.h>

/*
 * Linked list node
 */

typedef struct _ListNode {
    void *data;
    struct _ListNode *next;
} ListNode;

static inline void *list_node_data(ListNode *n) { return n->data; }
static inline ListNode *list_node_next(ListNode *n) { return n->next; }


/*
 * Linked list
 */

typedef struct _List {
    size_t size;
    void (*destroy_f)(void *data);    // data destructor
    
    ListNode *head;
    ListNode *tail;
} List;

void list_init(List *list, void (*destroy)(void *data));
void list_destroy(List *list);
int list_insert_next(List *list, ListNode *element, const void *data);
int list_remove_next(List *list, ListNode *element, void **data);
static inline size_t list_size(List *list) { return list->size; }
static inline ListNode *list_head(List *list) { return list->head; }
static inline ListNode *list_tail(List *list) { return list->tail; }
static inline int list_is_head(List *list, ListNode *node) { return (list->head == node); }
static inline int list_is_tail(ListNode *node) { return (node->next == NULL); }


/*
 * Queue
 */

typedef List Queue;

static inline void queue_init(Queue *q, void (*destroy)(void *data)) {
    list_init(q, destroy);
}

static inline void queue_destroy(Queue *q) {
    list_destroy(q);
}

static inline int queue_enqueue(Queue *q, void *data) {
    return (list_insert_next(q, list_tail(q), data));
}

static inline int queue_dequeue(Queue *q, void **data) {
    return (list_remove_next(q, NULL, data));
}

static inline size_t queue_size(Queue *q) {
    return list_size(q);
}


#endif /* slh_list_h */
