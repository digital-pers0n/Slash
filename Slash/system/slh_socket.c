//
//  slh_socket.c
//  Slash
//
//  Created by Terminator on 2018/07/25.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#include "slh_socket.h"
#include <stdlib.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <errno.h>
#include <string.h>

static inline void soc_error(const char *str, const char *str2) {
    fprintf(stderr, "%s: %s failed with error %i %s\n", str, str2, errno, strerror(errno));
}

#pragma mark - Connect

int soc_connect(Socket *s, char *path) {
    
    /* Create an endpoint for communication */
    if ((*s = socket(AF_UNIX, SOCK_STREAM, 0) == -1)) {
        soc_error(__func__, "socket()");
        return -1;
    }
    
    /* Initialize UNIX domain socket structure */
    struct sockaddr_un un;
    strcpy(un.sun_path, path);
    un.sun_family = AF_UNIX;
    un.sun_len = SUN_LEN(&un);
    
    /* Initiate connection */
    if (connect(*s, (struct sockaddr *)&un, un.sun_len) != 0) {
        soc_error(__func__, "connect()");
        return -1;
    }
    return 0;
}

