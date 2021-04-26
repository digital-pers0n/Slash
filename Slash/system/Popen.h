//
//  Popen.h
//  Slash
//
//  Created by Terminator on 2021/4/26.
//  Copyright © 2021年 digital-pers0n. All rights reserved.
//

#ifndef Popen_h
#define Popen_h

#import <stdio.h>

namespace SL {
/** A simple @c popen() wrapper. */
struct Popen {
    struct Mode {
        constexpr static const char *const Read = "r";
        constexpr static const char *const Write = "w";
        constexpr static const char *const ReadWrite = "r+";
    }; // struct Mode
    
    /**
     Open a process pipe.
     @param cmd A shell command line to execute. Must not be null.
     @param mode Specify a mode of the pipe. Must not be null.
                 "r" - read, "w" - write, "r+" - read/write.
     @param didLaunch A callback function that is only called if the operation 
        was successful. You have to @c pclose() the FILE pointer to dispose it.
     @param didFail A callback function that is only called if @c popen() 
                    function was failed.
     */
    template<typename Fn = void(*)(FILE*), typename Err = void(*)()>
    Popen(const char *cmd, const char *mode,
          Fn didLaunch, Err didFail) noexcept
    {
        if (auto p = popen(cmd, mode); p != nullptr) {
            didLaunch(p);
        } else {
            didFail();
        }
    } // Popen()
}; // struct Popen
} // namespace SL

#endif /* Popen_h */
