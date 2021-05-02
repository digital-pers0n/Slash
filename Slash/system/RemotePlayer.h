//
//  RemotePlayer.h
//  Slash
//
//  Created by Terminator on 2021/3/19.
//  Copyright © 2021年 digital-pers0n. All rights reserved.
//

#ifndef RemotePlayer_h
#define RemotePlayer_h

#import "Argv.h"
#import "ASPrint.h"
#import "Data.h"
#import "Dispatch.h"
#import "Spawn.h"

#import <sys/socket.h>
#import <sys/un.h>

namespace SL {
/** MPV IPC */
struct RemotePlayer {
    /** UNIX domain socket client. */
    struct IPC {
        /** Called when new data is available.
         @param buffer Received data. The data is not null-terminated.
         Only valid until return. Copy if you need to keep it.
         @param len number of characters in the @p buffer parameter.
         */
        using UpdateFn = void(*)(char *buffer, size_t len);
        
        /** Called when the connection was closed. */
        using CloseFn = void(*)();
        
        _Atomic(int) SocketDesc = -1;

        template<typename F1 = UpdateFn, typename F2 = CloseFn,
        typename F3 = Spawn::ErrorFn>
        static int Connect(const char *path, const Dispatch::QueueType &queue,
                           int attempts, F1 didUpdate, F2 didClose, F3 didFail)
        {
            int sd = [&] {
                /* Initialize UNIX domain socket structure */
                sockaddr_un un;
                
                const auto pathLen = strlen(path);
                const auto maxPathLen = sizeof(un.sun_path) - 1;
                if (pathLen > maxPathLen) { // socket path is too long
                    didFail(ENAMETOOLONG);
                    return -1;
                }
                
                memcpy(un.sun_path, path, pathLen);
                un.sun_path[pathLen] = '\0';
                un.sun_family = PF_LOCAL;
                const auto socketLen = socklen_t(offsetof(sockaddr_un, sun_path)
                                                 + pathLen);
                un.sun_len = socketLen;
                
                int result = -1, e = 0;
                
                timespec s = {
                    .tv_sec = 0,
                    .tv_nsec = decltype(s.tv_nsec)(0.3 * NSEC_PER_SEC)
                };
                
                for (; s.tv_sec < attempts; ++(s.tv_sec)) {
                    
                    if ((result = socket(PF_LOCAL, SOCK_STREAM,
                                         /*protocol*/ 0)) == -1)
                    {
                        perror("[RemotePlayer::IPC] socket()");
                        continue;
                    }
                    
                    nanosleep(&s, /*unslept amount*/ nullptr);
                    
                    /* Initiate connection */
                    if (connect(result, reinterpret_cast<sockaddr*>(&un),
                                socketLen) != 0)
                    {
                        e = errno;
                        perror("[RemotePlayer::IPC] connect()");
                        close(result);
                        continue;
                    }
                    puts("[RemotePlayer::IPC] Connection established.");
                    return result;
                }
                
                dprintf(STDERR_FILENO, "[RemotePlayer::IPC] Failed to connect "
                "to '%s' after %i attempts. %s\n", path, attempts, strerror(e));
                didFail(e);
                return -1;
            }(); // initiate connection
            
            if (sd == -1) return sd;
            
            fcntl(sd, F_SETFL, O_NONBLOCK); // enable non-blocking mode
            __block auto buf = SL::Data<char>(1024);
            auto src = Dispatch::Source::Read(sd, queue);
            src.onEvent(^{
                buf.expandIfShould(src.data() + 1);
                const auto received = recv(sd, buf, buf.Len, /*flags*/ 0);
                if (received < 1) {
                    if (received == -1) {
                        perror("[RemotePlayer::IPC] recv()");
                    }
                    src.cancel();
                    return;
                }
                didUpdate(buf.Bytes, received);
                
            }).onCancel(^{
                shutdown(sd, SHUT_RDWR);
                close(sd);
                didClose();
            }).resume();
            
            return sd;
        } // Connect()
        
        IPC() {}
        
        template<typename F1 = UpdateFn, typename F2 = CloseFn,
        typename F3 = Spawn::ErrorFn>
        IPC(const char *path, const Dispatch::QueueType queue, int attempts,
            F1 didUpdate, F2 didClose, F3 didFail)
        : SocketDesc(Connect(path, queue, attempts,
                             didUpdate, didClose, didFail)) {}
        
        ssize_t send(const char *msg, size_t len) const {
            return ::send(SocketDesc, msg, len, 0);
        }
        
        bool isValid() const {
            return (SocketDesc > -1);
        }
    }; // struct IPC
    
    /** Check if a MPV binary is outdated. */
    static bool IsLegacyMPV(const char *mpvPath) {
        const char fmt[] = "%s --list-options | grep input-ipc-server";
        char cmd[PATH_MAX + sizeof(fmt)];
        snprintf(cmd, sizeof(cmd), fmt, mpvPath);
        return bool(system(cmd));
    }
    using StartFn = void(*)(const RemotePlayer &mpv);
    
    IPC MPV;
    
    RemotePlayer() {}
    
    /** Launch MPV and establish an IPC connection.
     @param arguments A null-terminated array of MPV command line arguments. 
                      Must be @c posix_spawnp() compatible.
     @param queue A serial dispatch queue that will be used for callbacks.
     @param socketPath A UNIX domain socket path.
     @param isLegacyMPV A flag to indicate that MPV binary is outdated.
     @param attempts A number of attempts to establish the IPC connection.
     @param didConnect Called on the current thread if the IPC connection
                       was established.
     @param didUpdateOutLog Called on @p queue if mpv out stream was updated.
     @param didUpdateErrLog Called on @p queue if mpv err stream was updated.
     @param didRecvMsg Called on @p queue if an IPC message was received.
     @param didDisconnect Called on @p queue if the IPC connnection was closed.
     @param didFail Called on the current thread if the IPC connection cannot be
                    established.
     */
    template<typename F1 = StartFn, typename F2 = IPC::UpdateFn,
    typename F3 = IPC::UpdateFn, typename F4 = IPC::UpdateFn,
    typename F5 = IPC::CloseFn, typename F6 = Spawn::ErrorFn>
    RemotePlayer(const char *const *arguments, const Dispatch::QueueType queue,
                 const char * socketPath, bool isLegacyMPV, int attempts,
                 F1 didConnect, F2 didUpdateOutLog,F3 didUpdateErrLog,
                 F4 didRecvMsg, F5 didDisconnect, F6 didFail)
    {
        char arg[PATH_MAX + 64];
        snprintf(arg, sizeof(arg), isLegacyMPV ? "--input-unix-socket=%s"
                                   : "--input-ipc-server=%s", socketPath);
        
        auto args = Argv(arguments);
        if (!args.append(arg)) {
            didFail(errno);
            return;
        }
        
        Spawn { args, queue,
        [=](const Spawn &proc, int outFd, int errFd) { // didStart
            
            const auto logReader =
            [](const Dispatch::Queue q, int fd, auto notifier) {
                fcntl(fd, F_SETFL, O_NONBLOCK); // enable non-blocking mode
                __block auto buf = SL::Data<char>(1024);
                auto src = Dispatch::Source::Read(fd, q);
                src.onEvent(^{
                    buf.expandIfShould(src.data() + 1);
                    const auto bytesRead = read(fd, buf, buf.Len);
                    if (bytesRead < 1) {
                        if (bytesRead < 0) {
                            perror("[RemotePlayer] read()");
                        }
                        src.cancel();
                        return;
                    }
                    notifier(buf.Bytes, bytesRead);
                }).onCancel(^{
                    close(fd);
                }).resume();
            }; // logReader()
            
            logReader(queue, outFd, didUpdateOutLog);
            logReader(queue, errFd, didUpdateErrLog);
            
            MPV = IPC { socketPath, queue, attempts, didRecvMsg, didDisconnect,
            [&](int errorCode) { // didFail
                dprintf(STDERR_FILENO, "[RemotePlayer] IPC(): %i %s\n",
                        errorCode, strerror(errorCode));
                didFail(errorCode);
                proc.terminate();
            }}; // IPC()
            
            if (MPV.isValid()) {
                didConnect(*this);
            }
        },
        [](int exitCode){
             printf("[RemotePlayer] exit status: %i\n", WEXITSTATUS(exitCode));
        }, didFail }; // Spawn()
    } // RemotePlayer()
    
    bool isValid() const {
        return MPV.isValid();
    }
    
    void invalidate() {
        MPV.SocketDesc = -1;
    }
    
    template<typename Fn>
    void sendMessage(const char *msg, size_t len, Fn didFail) const {
        if (sendMessage(msg, len) < 0) {
            didFail();
        }
    }
    
    void sendMessage(const char *msg, size_t len, const char *errMsg) const {
        sendMessage(msg, len, [&errMsg]{ perror(errMsg); });
    }
    
    ssize_t sendMessage(const char *msg, size_t len) const {
        return MPV.send(msg, len);
    }
    
    void play() const {
        const char cmd[] = "{ \"command\": [\"set_property\", "
                           "\"pause\", \"no\"] }\n";
        sendMessage(cmd, sizeof(cmd) - 1, "[RemotePlayer] play()");
    }
    
    void sendCommand(const char *str) const {
        const auto &[cmd, len] = SL::ASPrint("{ \"command\": [%s] }\n", str);
        sendMessage(cmd, len, "[RemotePlayer] sendCommand()");
    }
    
    void loadFile(const char *path) const {
        const auto &[cmd, len] = SL::ASPrint("{ \"command\": [\"loadfile\", "
                                            "\"%s\"] }\n", path);
        sendMessage(cmd, len, "[RemotePlayer] loadFile()");
    }
    
    void setProperty(const char *str) const {
        const auto &[cmd, len] = SL::ASPrint("{ \"command\": [ \"set_property\","
                                            " %s ] }\n", str);
        sendMessage(cmd, len, "[RemotePlayer] setProperty()");
    }
    
    void setVideoFilter(const char *str) const {
        const auto &[cmd, len] = SL::ASPrint("{ \"command\": [ \"set_property\","
                                            " \"vf\", \"%s\" ] }\n", str);
        sendMessage(cmd, len, "[RemotePlayer] setVideoFilter()");
    }
    
    void seekTo(double seconds) const {
        const auto &[cmd, len] = SL::ASPrint("{ \"command\": [ \"seek\", %f, "
                                            "\"absolute+exact\"] }\n", seconds);
        sendMessage(cmd, len, "[RemotePlayer] seekTo()");
    }
    
    void quit() const {
        const char cmd[] = "{ \"command\": [\"quit\"] }\n";
        sendMessage(cmd, sizeof(cmd) - 1, "[RemotePlayer] quit()");
    }
}; // struct RemotePlayer
} // namespace SL

#endif /* RemotePlayer_h */
