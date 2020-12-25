//
//  SLTDefines.h
//  Slash
//
//  Created by Terminator on 2020/12/24.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#ifndef SLTDefines_h
#define SLTDefines_h

/**
 A very simple compile-time checker for key value paths.
 It doesn't cover all possible cases e.g self.@avg, CoreData attributes etc.
*/
#define KVP(object, keyPath) sizeof(object.keyPath) ? @#keyPath : @""

#endif /* SLTDefines_h */
