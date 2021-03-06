//
//  Encoder.h
//  Slash
//
//  Created by Terminator on 2021/3/5.
//  Copyright © 2021年 digital-pers0n. All rights reserved.
//

#ifndef Encoder_h
#define Encoder_h

#import "Data.h"
#import "Dispatch.h"
#import "Spawn.h"

namespace SL {
struct Encoder {
    /** Called once if ffmpeg was successfully launched.
     @param enc ffmpeg process
     */
    using StartEncodingFn = void(*)(const Spawn &enc);
    
    /** Called during encoding if the status text was updated.
     @param text A null-terminated string with the status text.
                 Only valid until return.
     @param len The number of characters in @p text.
     @param nFrames The number of frames already encoded, always 0 if no video
                    is being encoded.
     */
    using StatusUpdateFn = void(*)(const char *text, size_t len, int64_t nFrames);
    
    /** Called during encoding when the encoder log was updated.
     @param text An array of chars that is not null-terminated.
                 Only valid until return.
     @param len The number of characters in @p text
     */
    using LogUpdateFn = void(*)(const char *text, size_t len);
    
    /** Start encoding.
     @param args A null-terminated, @c posix_spawnp() compatible array of
                 ffmpeg arguments. Must not be null.
     @param queue A serial dispatch queue that will be used for notifications. 
                  Must not be null.
     @param didStart Called on the current thread
     @param didUpdate Called on the @p queue
     @param didLogUpdate Called on the @p queue
     @param didExit Called on the @p queue
     @param didFail Called on the current thread
     */
    template<
    typename F1 = StartEncodingFn, typename F2 = StatusUpdateFn,
    typename F3 = LogUpdateFn,     typename F4 = Spawn::ExitFn,
    typename F5 = Spawn::ErrorFn>
    Encoder(const char *const *args, const Dispatch::QueueType queue,
            F1 didStart, F2 didUpdate, F3 didLogUpdate, F4 didExit, F5 didFail)
    {
        Spawn { args, queue,
        [=](const Spawn &prc, int outFd, int errFd) { // launch
            didStart(prc);
            fcntl(errFd, F_SETFL, O_NONBLOCK); // enable non-blocking mode
            __block auto buf = Data<char>(1024);
            auto src = Dispatch::Source::Read(errFd, queue);
            src.onEvent(^{

                const auto cleanUp = [&] {
                    /* ffmpeg dumps everything into stderr.
                     This should not read any data normally. */
                    constexpr auto outReader = [](int fd, auto logUpdater) {
                        const size_t dataSize = 128;
                        char data[dataSize + 1];
                        ssize_t bytesRead = 0;
                        while ((bytesRead = read(fd, data, dataSize)) > 0) {
                            logUpdater(data, bytesRead);
                        }
                        if (bytesRead < 0) {
                            perror("[Encoder] outFd read()");
                        }
                    };
                    outReader(outFd, didLogUpdate);
                    src.cancel();
                };
                
                const auto est = src.data();
                if (!buf.expandIfShould(est + 1)) {
                    cleanUp();
                    return;
                }
                
                const auto bytesRead = read(errFd, buf, est);
                if (bytesRead < 1) {
                    if (bytesRead != 0) {
                        perror("[Encoder] errFd read()");
                    }
                    cleanUp();
                    return;
                }
                
                if (bytesRead < 200 && buf[bytesRead - 1] == '\r') {
                    constexpr auto nFramesFinder = [](const char *data) {
                        const char frame[] = "frame=";
                        const char *found = strnstr(data, frame,
                                                    sizeof(frame));
                        if (found) {
                            return int64_t(strtoll(found + (sizeof(frame) - 1),
                                             /*endptr*/ nullptr, /*base*/ 10));
                        }
                        return int64_t(0);
                    };
                    buf[bytesRead] = '\0';
                    didUpdate(buf.Bytes, bytesRead, nFramesFinder(buf.Bytes));
                    return;
                }
                didLogUpdate(buf.Bytes, bytesRead);
                
            }).onCancel(^{
                close(outFd);
                close(errFd);
            }).resume();
        }, didExit, didFail }; // Spawn
    } // Encoder
}; // struct Encoder
} // namespace SL

    
#endif /* Encoder_h */
