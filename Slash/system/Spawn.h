//
//  Spawn.h
//  Slash
//
//  Created by Terminator on 2021/2/17.
//  Copyright © 2021年 digital-pers0n. All rights reserved.
//

#ifndef Spawn_h
#define Spawn_h

#import "Dispatch.h"
#import <assert.h>      // assert()
#import <errno.h>
#import <signal.h>      // kill()
#import <spawn.h>       // posix_spawnp()
#import <sys/wait.h>    // waitpid()
#import <unistd.h>      // pipe()

__BEGIN_DECLS
extern char *const *environ;
__END_DECLS

/** @file posix_spawnp() wrapper.
 Uses dispatch_source to monitor the spawned process and asynchronously notfies 
 the client after the process exited. */

namespace SL {

struct Spawn {
    
struct FileActions {
    using Type = posix_spawn_file_actions_t;
    Type Actions = {0};
    
    FileActions() {
        posix_spawn_file_actions_init(&Actions);
    }
    
    FileActions(const int stdOut[2], const int stdErr[2]) : FileActions() {
        addClose(stdOut[0]);
        addClose(stdErr[0]);
        addDup2(stdOut[1], 1);
        addDup2(stdErr[1], 2);
        addClose(stdOut[1]);
        addClose(stdErr[1]);
    }
    
    ~FileActions() {
        posix_spawn_file_actions_destroy(&Actions);
    }
    
    int addClose(int fd) {
        return posix_spawn_file_actions_addclose(&Actions, fd);
    }
    
    int addDup2(int fd, int newFd) {
        return posix_spawn_file_actions_adddup2(&Actions, fd, newFd);
    }
    
    operator const Type*() const {
        return &Actions;
    }
}; // struct FileActions
    
    _Atomic(pid_t) Pid = -1;
    
    /** Called if an error occurs.
     @param errorCode errno code.
     */
    using ErrorFn = void(*)(int errorCode);
    
    /** Called only if the process was successfully spawned.
     @param proc the spawned process.
     @param outFd the standard out of the process. Pass to @c close() when done.
     @param errFd the error out of the process. Pass to @c close() when done.
     */
    using ExecFn = void(*)(const Spawn &proc, int outFd, int errFd);
    
    /** Called when the process exited.
     @param exitStatus the exit status returned by the process.
     Can be examined with WEXITSTATUS().
     */
    using ExitFn = void(*)(int exitStatus);
    
    template<typename F = ErrorFn> static
    bool CreatePipes(int outPipe[2], int errPipe[2], F didFail) {
        if (pipe(outPipe)) {
            didFail(errno);
            return false;
        }
        if (pipe(errPipe)) {
            close(outPipe[0]);
            close(outPipe[1]);
            didFail(errno);
            return false;
        }
        return true;
    }
    
    template<typename F = ErrorFn>
    static int Exec(const char *const *args, const char *const *env,
                    int outPipe[2], int errPipe[2], F didFail)
    {
        if (!CreatePipes(outPipe, errPipe, didFail)) return -1;
        
        pid_t pid = 0;
        int e = posix_spawnp(&pid, args[0], FileActions(outPipe, errPipe),
                             /*posix_spawnattr_t*/ nullptr,
                             const_cast<char* const*>(args),
                             const_cast<char* const*>(env));
        /* close child-side of pipes */
        close(outPipe[1]);
        close(errPipe[1]);
        
        if (e) {
            close(outPipe[0]);
            close(errPipe[0]);
            didFail(e);
            return -1;
        }
        return pid;
    }
    
    static int Signal(pid_t pid, int sig) {
        assert(pid > 0 && "pid is not valid.");
        return kill(pid, sig);
    }
    
    Spawn() {}
    
    template<typename F1 = ExecFn, typename F2 = ExitFn, typename F3 = ErrorFn>
    Spawn(const char *const *args, const Dispatch::QueueType &queue,
          F1 didLaunch, F2 didExit, F3 didFail)
    {
        int outPipe[2] = {-1};
        int errPipe[2] = {-1};
        pid_t pid = Exec(args, ::environ, outPipe, errPipe, didFail);
        if (pid < 1) return;
        
        auto source = Dispatch::Source::Proc(pid, queue);
        source.onEvent(^{
            source.cancel();
        }).onCancel(^{
            int exitCode;
            waitpid(pid, &exitCode, 0);
            didExit(exitCode);
        }).resume();
        
        Pid = pid;
        didLaunch(*this, outPipe[0], errPipe[0]);
    }
    
    template<typename F1 = ExecFn, typename F2 = ExitFn, typename F3 = ErrorFn>
    Spawn(const char *const *args, F1 didLaunch, F2 didExit, F3 didFail)
    : Spawn(args, Dispatch::Queue::GetGlobal(), didLaunch, didExit, didFail) {}
    
    bool isRunning() const {
        return (Pid > 0);
    }
    
    int signal(int sig) const {
       return Signal(Pid, sig);
    }
    
    int interrupt() const {
        return signal(SIGINT);
    }
    
    int terminate() const {
        return signal(SIGTERM);
    }
    
    int suspend() const {
        return signal(SIGSTOP);
    }
    
    int resume() const {
        return signal(SIGCONT);
    }
    
    operator pid_t() const {
        return Pid;
    }
}; // struct Spawn
} // namespace SL

#endif /* Spawn_h */
