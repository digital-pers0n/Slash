//
//  MPVLock.h
//  Slash
//
//  Created by Terminator on 2020/05/05.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#ifndef MPVLock_h
#define MPVLock_h

#import <os/lock.h>
#import <libkern/OSAtomic.h>
#import <pthread/pthread.h>
#import <pthread/pthread_spis.h>

#ifndef USE_OS_LOCK
#define USE_OS_LOCK 1
#else
#define USE_OS_LOCK 0
#endif

#ifndef ENABLE_PTHREAD_UNSAFE_HACK
#define ENABLE_PTHREAD_UNSAFE_HACK 0
#endif

#if !USE_OS_LOCK && (!MAC_OS_X_VERSION_10_14 || \
    MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_14)
#define ENABLE_PTHREAD_FIRSTFIT_COMPAT 1
#else 
#define ENABLE_PTHREAD_FIRSTFIT_COMPAT 0
#endif

/*
 On Mojave and higher pthread_mutex is almost same as os_unfair_lock, but 
 on older systems, the os_unfair_lock is usually better.
 */
typedef struct MPVLock_ {
#if USE_OS_LOCK
    os_unfair_lock lock;
#else 
    pthread_mutex_t lock;
#endif
} MPVLock;

void mpv_lock_init(MPVLock * l);
void mpv_lock_lock(MPVLock * l);
int mpv_lock_trylock(MPVLock * l);
void mpv_lock_unlock(MPVLock * l);
void mpv_lock_destroy(MPVLock * l);

#endif /* MPVLock_h */
