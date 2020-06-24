//
//  MPVKitDefines.h
//  Slash
//
//  Created by Terminator on 2020/06/23.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#ifndef MPVKitDefines_h
#define MPVKitDefines_h

#if __has_attribute(objc_direct)
#define OBJC_DIRECT __attribute__((objc_direct))
#define OBJC_DIRECT_MEMBERS __attribute__((objc_direct_members))
#else
#define OBJC_DIRECT
#define OBJC_DIRECT_MEMBERS
#endif

#endif /* MPVKit_h */
