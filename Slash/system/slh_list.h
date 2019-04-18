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


#pragma mark - ListNode

/*
 * Linked list node
 */

typedef struct _ListNode {
    void *data;
    struct _ListNode *next;
} ListNode;


/**
 * Get the pointer to data associated with the list node.
 */
static inline void *list_node_data(ListNode *n) { return n->data; }

/**
 * Get the next list node.
 */
static inline ListNode *list_node_next(ListNode *n) { return n->next; }


#pragma mark - List

/*
 * Linked list
 */

typedef struct _List {
    size_t size;
    void (*destroy_f)(void *data);    // data destructor
    
    ListNode *head;
    ListNode *tail;
} List;

/**
 * Initialize a linked list. Must be called before any other operation.
 * 
 * @param list a List structure to be initialized. Must not be NULL.
 * 
 * @param destroy a user-defined function to automatically free allocated data
 *                that will be called when the list is destroyed by the list_destroy() function.
 *                Must be NULL if data is not dynamically allocated.
 */
void list_init(List *list, void (*destroy)(void *data));

/**
 * Destroy the linked list. Remove all nodes, and automatically deallocates
 * all data associated with the nodes if the list was initialized with the 
 * non-NULL destroy argument.
 */
void list_destroy(List *list);

/**
 * Insert a new node in the linked list. 
 * 
 * @param node the node after which a new node will be inserted.
 *             if this parameter is NULL, then the new node will be inserted
 *             at the head of the linked list.
 * 
 * @param data the pointer to data that will be stored in the new node.
 *
 * @return 0 on success, -1 otherwise
 */
int list_insert_next(List *list, ListNode *node, const void *data);

/**
 * Remove the node from the linked list.
 *
 * @param node the node after which the node will be removed.
 *             If this parameter is NULL, then the node will be removed
 *             from the head of the linked list.
 *
 * @param data the pointer to the data that was previously stored in the removed node.
 *
 * @return 0 on success, -1 otherwise.
 */
int list_remove_next(List *list, ListNode *node, void **data);

/**
 * Get the size of the linked list.
 */
static inline size_t list_size(List *list) { return list->size; }

/**
 * Get the head of the linked list.
 */
static inline ListNode *list_head(List *list) { return list->head; }

/**
 * Get the tail of the linked list.
 */
static inline ListNode *list_tail(List *list) { return list->tail; }

/**
 * Check if a node is the head of the linked list.
 */
static inline int list_is_head(List *list, ListNode *node) { return (list->head == node); }

/**
 * Check if a node is the tail of the linked list.
 */
static inline int list_is_tail(ListNode *node) { return (node->next == NULL); }


#pragma mark - Queue

/*
 * Queue
 */

typedef List Queue;

/**
 * Initialize a queue. Must be called before any other operation.
 * 
 * @param queue a queue to be initialized. Must not be NULL.
 * 
 * @param destroy a user-defined function to automatically free allocated data
 *                that will be called when the queue is destroyed by the queue_destroy() function.
 *                Must be NULL if data is not dynamically allocated.
 */
static inline void queue_init(Queue *queue, void (*destroy)(void *data)) {
    list_init(queue, destroy);
}

/**
 * Destroy the queue. Automatically deallocate all data associated 
 * with the nodes if the queue was initialized with the non-NULL destroy argument.
 */
static inline void queue_destroy(Queue *queue) {
    list_destroy(queue);
}

/**
 * Enqueue a new node at the tail of the queue. 
 * 
 * @param data the pointer to data that will be stored in the new node.
 *
 * @return 0 on success, -1 otherwise
 */
static inline int queue_enqueue(Queue *queue, const void *data) {
    return (list_insert_next(queue, list_tail(queue), data));
}

/**
 * Dequeue the node from the head of the queue.
 *
 * @param data the pointer to the data that was previously associated with the dequeued node.
 *
 * @return 0 on success, -1 otherwise.
 */
static inline int queue_dequeue(Queue *queue, void **data) {
    return (list_remove_next(queue, NULL, data));
}

/**
 * Get the pointer to data stored at the head of the queue.
 *
 * @return the pointer to data, or NULL if the queue is empty.
 */
static inline void *queue_peek(Queue *queue) {
    return (queue->head) ? queue->head->data : NULL;
}

/**
 * Get the number of nodes in the queue.
 */
static inline size_t queue_size(Queue *q) {
    return list_size(q);
}


#endif /* slh_list_h */
