//
//  slh_socket.h
//  Slash
//
//  Created by Terminator on 2018/07/25.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#ifndef slh_socket_h
#define slh_socket_h

#include <stdio.h>

typedef int Socket;


/* Connect/Disconnect */
int soc_connect(Socket *s, char *path);
int soc_shutdown(Socket *s);

/* Send/Receive Data */
ssize_t soc_send(Socket *s, char *msg, size_t len);
ssize_t soc_recv(Socket *s, char *buf, size_t len);

#endif /* slh_socket_h */
