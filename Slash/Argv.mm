//
//  Argv.mm
//  Slash
//
//  Created by Terminator on 2021/2/18.
//  Copyright © 2021年 digital-pers0n. All rights reserved.
//

#import "Argv.h"

namespace SL {

char **ArgvAlloc(size_t len) noexcept {
    return static_cast<char**>(calloc(len, sizeof(char*)));
}

constexpr size_t ArgvCount(ArgvType argv) {
    size_t len = 0;
    auto ptr = argv;
    while (*(ptr++) != nullptr) {
        len++;
    }
    return len;
}

char **ArgvAlloc(ArgvType src) {
    return ArgvAlloc(ArgvCount(src) + 1);
}

void ArgvDealloc(char **argv) {
    auto ptr = argv;
    while (*ptr != nullptr) {
        free(*(ptr++));
    }
    free(argv);
}

void ArgvCopy(char **dst, ArgvType src) {
    size_t len = 0;
    auto ptr = src;
    while (*ptr != nullptr) {
        dst[len++] = strdup(*(ptr++));
    }
    dst[len] = nullptr;
}

char **ArgvCopy(ArgvType src) {
    char **dst = ArgvAlloc(src);
    if (!dst) return nullptr;
    
    ArgvCopy(dst, src);
    return dst;
}

char **ArgvCopy(NSArray<NSString *> *src) noexcept {
    const size_t len = src.count;
    auto args = ArgvAlloc(len + 1);
    if (!args) return nullptr;
    
    size_t i = 0;
    for (NSString *str in src) {
        args[i++] = strdup(str.UTF8String);
    }
    args[i] = nullptr;
    return args;
}

char **ArgvAppend(char ***dst, const char *arg) noexcept {
    const auto len = ArgvCount(*dst);
    auto tmp = static_cast<char**>(realloc(*dst, (len + 2) * sizeof(char*)));
    if (!tmp) return nullptr;
    
    *dst = tmp;
    (*dst)[len] = strdup(arg);
    (*dst)[len + 1] = nullptr;
    return *dst;
}

void ArgvPrint(ArgvType argv) {
    puts("{");
    while (*(argv) != nullptr) {
        putchar('\t');
        puts(*(argv++));
    }
    puts("}");
}

} // namespace SL
