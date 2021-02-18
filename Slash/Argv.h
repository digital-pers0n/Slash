//
//  Argv.h
//  Slash
//
//  Created by Terminator on 2021/2/18.
//  Copyright © 2021年 digital-pers0n. All rights reserved.
//

#ifndef Argv_h
#define Argv_h

#import <Foundation/Foundation.h>

/** @file Functions to operate on null-terminated arrays of C-strings.
 Needed for @c posix_spawn(). */

namespace SL {
using ArgvType = const char* const*;

/**
 Allocate an array. Must be deallocated with @c ArgvDealloc() later.
 @param len an initial size of the array.
 @return an allocated array or nullptr if @c calloc() failed.
 */
char **ArgvAlloc(size_t len) noexcept;

/**
 Allocate an array that has same size as @p src.
 @param src a null-terminated array of C-strings.
 @return an allocated array or nullptr if @c calloc() failed.
 */
char **ArgvAlloc(ArgvType src);

/**
 Deallocate @p argv.
 @param argv an array of null-terminated C-strings.
 */
void ArgvDealloc(char **argv);

/**
 Make a copy of @p src. Upon return @p dst is filled with contents of @p src.
 @param dst an array with enough space to hold contents of @p src.
 @param src a null-terminated array of C-strings.
 */
void ArgvCopy(char **dst, ArgvType src);

/**
 Make a copy of @p src.
 @param src a null-terminted array of C-strings.
 @return a copy of @p src or nullptr if @c calloc() fails.
 */
char **ArgvCopy(ArgvType src);

/**
 Copy contents of @p src.
 @param src an NSArray of NSStrings.
 @return a copy of @p src or nullptr if @c calloc() fails.
 */
char **ArgvCopy(NSArray<NSString *> *src) noexcept;

/**
 Append @p arg to @p dst.
 @param dst a pointer to an array of null-terminated C-strings.
            Must not be null.
 @param arg an argument to append. Must not be null.
 @return @p dst that contains @p arg or nullptr if @c realloc() fails.
         In case of an error @p dst is left untouched.
 */
char **ArgvAppend(char ***dst, const char *arg) noexcept;

/**
 Find number of arguments in @p argv.
 @param argv a null-terminated array of C-strings.
 @return the number of elements in @p argv minus the terminating null string.
 */
constexpr size_t ArgvCount(ArgvType argv);

/**
 Print contents of @p argv to stdout.
 @param argv a null-terminated array of C-strings.
 */
void ArgvPrint(ArgvType argv);

} // namespace SL

#endif /* Argv_h */
