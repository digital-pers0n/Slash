//
//  MPVLock.h
//  Slash
//
//  Created by Terminator on 2020/05/05.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#include <stdio.h>
#include "MPVLock.h"

#define always_inline __attribute__((__always_inline__))

// OSSpinLock inline wrappers for compatibility with os_unfair_lock on
// macOS 10.11 and lower.
#if USE_OS_LOCK && MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_12
_Static_assert(sizeof(OSSpinLock) == sizeof(os_unfair_lock),
      "os_unfair_lock and OSSpinLock are not interchangeable on your system.\n"
      "Set deployment target to macOS 10.12 or higher to fix this error.");

always_inline
void os_unfair_lock_lock(os_unfair_lock_t lock) {
    OSSpinLock * l = (OSSpinLock * )lock;
    OSSpinLockLock(l);
}

always_inline
bool os_unfair_lock_trylock(os_unfair_lock_t lock) {
    OSSpinLock * l = (OSSpinLock * )lock;
    return OSSpinLockTry(l);
}

always_inline
void os_unfair_lock_unlock(os_unfair_lock_t lock) {
    OSSpinLock * l = (OSSpinLock * )lock;
    OSSpinLockUnlock(l);
}

#endif

always_inline
void mpv_lock_init(MPVLock * l) {
#if USE_OS_LOCK
    l->lock = OS_UNFAIR_LOCK_INIT;
#else
    
    pthread_mutexattr_t mattr;
    pthread_mutexattr_init(&mattr);
    
#if ENABLE_PTHREAD_FIRSTFIT_COMPAT
    // From Apple's libpthread/src/pthread_mutex.c
    // pthread_mutexattr_setpolicy_np() :
    //
    // <rdar://problem/35844519> the first-fit implementation was broken
    // pre-Liberty so this mapping exists to ensure that the old first-fit
    // define (2) is no longer valid when used on older systems.
    //
    // From the pthread_mutexattr man page:
    //
    // Prior to macOS 10.14 (iOS and tvOS 12.0, watchOS 5.0) the only available
    // pthread mutex policy mode was PTHREAD_MUTEX_POLICY_FAIRSHARE_NP.
    // macOS 10.14 (iOS and tvOS 12.0, watchOS 5.0) introduces
    // PTHREAD_MUTEX_POLICY_FIRSTFIT_NP and also makes this the default mode for
    // mutexes initialized without a policy attribute set. Attempting to use
    // pthread_mutexattr_setpolicy_np to set the policy of a pthread_mutex_t to
    // PTHREAD_MUTEX_POLICY_FIRSTFIT_NP on earlier releases will fail with
    // EINVAL and the mutex will continue to operate in fairshare mode.
    //
    // So Apple broke compatibility on purpose. They also provided incorrect
    // information that fistfit policy wasn't avalaible prior to macOS 10.14,
    // which is total nonsense, it was introduced in macOS 10.7
    
    // _PTHREAD_MUTEX_POLICY_FIRSTFIT defined as (2) on 10.13 and lower.
    if (pthread_mutexattr_setpolicy_np(&mattr, 2) != 0) {
        // _PTHREAD_MUTEX_POLICY_FIRSTFIT defined as (3) on 10.14 and higher.
        // Yet in the libpthread/src/internal.h _PTHREAD_MTX_OPT_POLICY_FIRSTFIT
        // defined as (2) and Apple use it internally instead of (3)
        pthread_mutexattr_setpolicy_np(&mattr, 3);
    }
#else
    pthread_mutexattr_setpolicy_np(&mattr, _PTHREAD_MUTEX_POLICY_FIRSTFIT);
#endif // ENABLE_PTHREAD_FIRSTFIT_COMPAT
    
    pthread_mutex_init(&l->lock, &mattr);
    pthread_mutexattr_destroy(&mattr);
    
#if ENABLE_PTHREAD_FIRSTFIT_COMPAT && ENABLE_PTHREAD_UNSAFE_HACK
    
    // rdar://18148854 pthread_mutex_lock & pthread_mutex_unlock fastpath
    
    // _PTHREAD_MUTEX_SIG_fast 0x4D55545A 'MUTZ' in libpthread/src/internal.h
    // Enabled by default on 10.14+ when initialized with PTHREAD_MUTEX_NORMAL
    // type and firstfit or fairshare policy attributes. It's off by default
    // on older systems when the firstfit policy is used.
    // Setting the signature manually enables fastpath on older systems.
    
    // NOTE: This can potentially crash or deadlock your program.
    // Tested on 10.11 and 10.13
    // On macOS 10.13 this can make firstfist mutexes ~30% faster.

    l->lock.__sig = 0x4D55545A;
    
#endif // ENABLE_PTHREAD_FIRSTFIT_COMPAT && ENABLE_PTHREAD_UNSAFE_HACK
    
#endif // USE_OS_LOCK
}

always_inline
void mpv_lock_lock(MPVLock * l) {
#if USE_OS_LOCK
    os_unfair_lock_lock(&l->lock);
#else
    pthread_mutex_lock(&l->lock);
#endif
}

always_inline
void mpv_lock_unlock(MPVLock * l) {
#if USE_OS_LOCK
    os_unfair_lock_unlock(&l->lock);
#else
    pthread_mutex_unlock(&l->lock);
#endif
}

always_inline
int mpv_lock_trylock(MPVLock *l) {
#if USE_OS_LOCK
    return os_unfair_lock_trylock(&l->lock);
#else 
    return pthread_mutex_trylock(&l->lock);
#endif
}

always_inline
void mpv_lock_destroy(MPVLock * l) {
#if USE_OS_LOCK
    // l->lock = OS_UNFAIR_LOCK_INIT;
#else
    pthread_mutex_destroy(&l->lock);
#endif
}
