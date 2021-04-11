//
//  SPrint.h
//  Slash
//
//  Created by Terminator on 2021/4/11.
//  Copyright © 2021年 digital-pers0n. All rights reserved.
//

#ifndef SPrint_h
#define SPrint_h

#import <Foundation/Foundation.h>

template<size_t MaxLen = 32>
struct SPrint {
    static_assert(MaxLen > 0, "The length of c-strings cannot be 0");
    char Text[MaxLen];
    size_t Len = 0;
    SPrint &operator=(const SPrint &) = delete;
    SPrint(const SPrint &) = delete;
    
    SPrint(const char *__restrict fmt, ...) noexcept __printflike(2, 3) {
        va_list ap;
        va_start(ap, fmt);
        const auto len = vsnprintf(Text, MaxLen, fmt, ap);
        if (len > 0) {
            if (size_t _ = len; _ > (MaxLen - 1)) {
                Len = MaxLen - 1;
            } else {
                Len = len;
            }
        }
        va_end(ap);
    }

    operator NSString*() const {
        return [[NSString alloc] initWithBytes:Text length:Len
                                      encoding:NSUTF8StringEncoding];
    }
    
    operator const char*() const {
        return Text;
    }
}; // struct SPrint
} // namespace SL

#endif /* SPrint_h */
