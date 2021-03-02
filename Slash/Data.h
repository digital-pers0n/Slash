//
//  Data.h
//  Slash
//
//  Created by Terminator on 2021/3/2.
//  Copyright © 2021年 digital-pers0n. All rights reserved.
//

#ifndef Data_h
#define Data_h

namespace SL {
    
/** A very simple malloc/realloc wrapper. */
template<typename Type>
struct Data {
    size_t Len;
    Type *Bytes;
    
    Data(const Data&) = delete;
    Data &operator=(const Data&) = delete;
    
    /* This allows safe __block storage type */
    Data(Data &&other) : Bytes(other.Bytes), Len(other.Len) {
        other.Bytes = nullptr;
    }
    
    Data() : Data(64) {}
    Data(size_t len) noexcept :
    Bytes(static_cast<Type*>(malloc(sizeof(Type) * (len ?: 1)))), Len(len) {}
    
    ~Data() {
        if (Bytes) {
            free(Bytes);
        }
    }
    
    size_t totalSize() const {
        return sizeof(Type) * Len;
    }
    
    bool shouldExpand(size_t newLen) const {
        return (newLen > Len);
    }
    
    bool expandIfShould(size_t newLen) {
        if (!shouldExpand(newLen)) return true;
        return expand(newLen);
    }
    
    bool expand(size_t newLen) noexcept {
        assert(newLen > Len && "new size is too small.");
        auto tmp = static_cast<Type*>(realloc(Bytes, sizeof(Type) * newLen));
        if (!tmp) {
            perror("[Data] realloc()");
            return false;
        }
        Bytes = tmp;
        Len = newLen;
        return true;
    }
    
    Type &operator[](size_t idx) const {
        assert(idx < Len && "out of bounds access.");
        return Bytes[idx];
    }
    
    operator void*() const {
        return Bytes;
    }
}; // struct Data
}  // namespace SL


#endif /* Data_h */
