//
//  ASPrint.h
//  Slash
//
//  Created by Terminator on 2021/3/14.
//  Copyright © 2021年 digital-pers0n. All rights reserved.
//

#ifndef ASPrint_h
#define ASPrint_h

#import <stdio.h>

namespace SL {
/** asprintf() RAII wrapper */
struct ASPrint {
    char *Text = nullptr;
    size_t Len = 0;
    
    ASPrint &operator=(const ASPrint &) = delete;
    ASPrint(const ASPrint &) = delete;
    
    ASPrint(const char *__restrict fmt, ...) noexcept __printflike(2, 3) {
        va_list ap;
        va_start(ap, fmt);
        const auto len = vasprintf(&Text, fmt, ap);
        if (len > 0) {
            Len = len;
        }
        va_end(ap);
    }
    
    ~ASPrint() {
        free(Text);
    }
    
    operator const char*() const {
        return Text;
    }
}; // struct ASPrint
} // namespace SL

#endif /* ASPrint_h */
