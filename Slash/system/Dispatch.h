//
//  Dispatch.h
//  Slash
//
//  Created by Terminator on 2021/2/16.
//  Copyright © 2021年 digital-pers0n. All rights reserved.
//

#ifndef Dispatch_h
#define Dispatch_h

#import <dispatch/dispatch.h>

/// @file libdispatch inline wrappers.

namespace Dispatch {
using ObjectType = dispatch_object_t;
using QueueType = dispatch_queue_t;
using SourceType = dispatch_source_t;
using GroupType = dispatch_group_t;
using TimeType = dispatch_time_t;
using BlockType = dispatch_block_t;
using FunctionType = dispatch_function_t;

template<typename Type>
struct Object {
    Type DispatchObject = {0};
    
    Object(const Type &val) : DispatchObject(val) {};
    Object(const Object &val) : DispatchObject(val.DispatchObject) {}
    
    auto & operator=(const Object &other) {
        DispatchObject = other.DispatchObject;
        return *this;
    }
    
    auto & operator=(const Type &other) {
        DispatchObject = other;
        return *this;
    }
    
    void finalizer(FunctionType f) const {
        dispatch_set_finalizer_f(DispatchObject, f);
    }
    
    void context(void *ctx) const {
        dispatch_set_context(DispatchObject, ctx);
    }
    
    void *context() const {
        dispatch_get_context(DispatchObject);
    }
    
    void suspend() const {
        dispatch_suspend(DispatchObject);
    }
    
    void resume() const {
        dispatch_resume(DispatchObject);
    }
    
    void activate() const {
        dispatch_activate(DispatchObject);
    }
    
    // non-ARC or OS_OBJECT_HAVE_OBJC_SUPPORT == 0
    void retain() const {
        dispatch_retain(DispatchObject);
    }
    
    // non-ARC or OS_OBJECT_HAVE_OBJC_SUPPORT == 0
    void release() const {
        dispatch_release(DispatchObject);
    }
    
    operator Type() const {
        return DispatchObject;
    }
    
    operator ObjectType() const {
        return DispatchObject;
    }
}; // struct Object

struct Time {
    using Type = TimeType;
    Type Value = {0};
    
    constexpr static Type Now() {
        return DISPATCH_TIME_NOW;
    }
    
    constexpr static Type Forever() {
        return DISPATCH_TIME_FOREVER;
    }
    
    struct Interval {
        template<typename T>
        static auto Usec(T delta) {
            return (delta * NSEC_PER_USEC);
        }
        
        template<typename T>
        static auto Msec(T delta) {
            return (delta * NSEC_PER_MSEC);
        }
        
        template<typename T>
        static auto Sec(T delta) {
            return (delta * NSEC_PER_SEC);
        }
    };
    
    static Type Nsec(int64_t delta) {
        return dispatch_time(Now(), delta);
    }
    
    static Type Usec(int64_t delta) {
        return Nsec(Interval::Usec(delta));
    }
    
    static Type Msec(int64_t delta) {
        return Nsec(Interval::Msec(delta));
    }
    
    static Type Sec(int64_t delta) {
        return Nsec(Interval::Sec(delta));
    }
    
    Time(int64_t delta) : Value(Nsec(delta)) {}
    Time(double delta) : Value(Nsec(Interval::Sec(delta))) {}
    Time(const Type &val) : Value(val) {}
    
    auto & operator=(const Type &val) {
        Value = val;
        return *this;
    }
    
    operator Type() const {
        return Value;
    }
    
}; // struct Time

struct Queue : public Object<QueueType> {
    using Type = QueueType;
    using Object::Object;
    
    enum Priority {
        Default = DISPATCH_QUEUE_PRIORITY_DEFAULT,
        High = DISPATCH_QUEUE_PRIORITY_HIGH,
        Low = DISPATCH_QUEUE_PRIORITY_LOW,
        Background = DISPATCH_QUEUE_PRIORITY_BACKGROUND
    }; // enum Priority
    
    static Type GetMain() {
        return dispatch_get_main_queue();
    }
    
    static Type GetGlobal(Priority priority) {
        return dispatch_get_global_queue(priority, 0);
    }
    
    static Type GetGlobal() {
        return GetGlobal(Priority::Default);
    }
    
    static Type CreateSerial(const char *label) {
        return dispatch_queue_create(label, DISPATCH_QUEUE_SERIAL);
    }
    
    static Type CreateConcurrent(const char *label) {
        return dispatch_queue_create(label, DISPATCH_QUEUE_CONCURRENT);
    }
    
    static Queue Main() {
        return Queue(GetMain());
    }
    
    auto & async(BlockType block) const {
        dispatch_async(DispatchObject, block);
        return *this;
    }
    
    auto & async(void *ctx, FunctionType fn) const {
        dispatch_async_f(DispatchObject, ctx, fn);
        return *this;
    }
    
    auto & async(TimeType delay, BlockType block) const {
        dispatch_after(delay, DispatchObject, block);
        return *this;
    }
    
    auto & async(TimeType delay, void *ctx, FunctionType fn) const {
        dispatch_after_f(delay, DispatchObject, ctx, fn);
        return *this;
    }
    
    auto & sync(BlockType block) const {
        dispatch_sync(DispatchObject, block);
        return *this;
    }
    
    auto & sync(void *ctx, FunctionType fn) const {
        dispatch_sync_f(DispatchObject, ctx, fn);
        return *this;
    }
    
    auto & apply(size_t iterations, void (^block)(size_t)) const {
        dispatch_apply(iterations, DispatchObject, block);
        return *this;
    }
    
    auto & apply(size_t iterations, void *ctx, void(*f)(void*, size_t)) const {
        dispatch_apply_f(iterations, DispatchObject, ctx, f);
        return *this;
    }
    
}; // struct Queue

inline Queue GlobalQueue(Queue::Priority priority) {
    return Queue(Queue::GetGlobal(priority));
}

inline Queue GlobalQueue() {
    return GlobalQueue(Queue::Priority::Default);
}

inline Queue MainQueue() {
    return Queue::Main();
}

inline Queue CreateSerialQueue(const char *label) {
    return Queue(Queue::CreateSerial(label));
}

inline Queue CreateSerialQueue() {
    return CreateSerialQueue("com.dispatch.queue.serial");
}

inline Queue CreateConcurrentQueue(const char *label) {
    return Queue(Queue::CreateConcurrent(label));
}

inline Queue CreateConcurrentQueue() {
    return CreateConcurrentQueue("com.dispatch.queue.concurrent");
}

struct Group : public Object<GroupType> {
    using Object::Object;
    
    Group() : Object(dispatch_group_create()) {}
    
    auto & async(QueueType q, BlockType block) const {
        dispatch_group_async(DispatchObject, q, block);
        return *this;
    }
    
    auto & notify(QueueType q, BlockType block) const {
        dispatch_group_notify(DispatchObject, q, block);
        return *this;
    }
    
    auto & wait(TimeType timeout) const {
        dispatch_group_wait(DispatchObject, timeout);
        return *this;
    }
    
    auto & wait() const {
        return this->wait(Time::Forever());
    }
    
}; // struct Group

struct Source : public Object<SourceType> {
    using Object::Object;
    
    struct Kind {
        using Type = dispatch_source_type_t;
        constexpr static Type Proc() {
            return DISPATCH_SOURCE_TYPE_PROC;
        }
        constexpr static Type Read() {
            return DISPATCH_SOURCE_TYPE_READ;
        }
        constexpr static Type Timer() {
            return DISPATCH_SOURCE_TYPE_TIMER;
        }
    };
    
    static Source Proc(pid_t pid, unsigned long mask, QueueType q) {
        return Source(Kind::Proc(), pid, mask, q);
    }
    
    static Source Proc(pid_t pid, QueueType q) {
        return Proc(pid, DISPATCH_PROC_EXIT, q);
    }
    
    static Source Read(int fd, QueueType q) {
        return Source(Kind::Read(), fd, 0, q);
    }
    
    static Source Timer(unsigned long mask, QueueType q) {
        return Source(Kind::Timer(), 0, mask, q);
    }
    
    static Source Timer(QueueType q) {
        return Timer(0, q);
    }
    
    static Source StrictTimer(QueueType q) {
        return Timer(DISPATCH_TIMER_STRICT, q);
    }
    
    Source(Kind::Type type, uintptr_t handle,
           unsigned long mask, QueueType q)
    : Object(dispatch_source_create(type, handle, mask, q)) {}
    
    auto & onEvent(BlockType block) const {
        dispatch_source_set_event_handler(DispatchObject, block);
        return *this;
    }
    
    auto & onCancel(BlockType block) const {
        dispatch_source_set_cancel_handler(DispatchObject, block);
        return *this;
    }
    
    auto & onEvent(void *ctx, FunctionType fn) const {
        context(ctx);
        dispatch_source_set_event_handler_f(DispatchObject, fn);
        return *this;
    }
    
    auto & onCancel(void *ctx, FunctionType fn) const {
        context(ctx);
        dispatch_source_set_cancel_handler_f(DispatchObject, fn);
        return *this;
    }
    
    auto & schedule(TimeType start, uint64_t interval = Time::Forever(),
                    uint64_t leeway = 0) const
    {
        dispatch_source_set_timer(DispatchObject, start, interval, leeway);
        return *this;
    }
    
    auto & schedule(TimeType start, double interval, uint64_t leeway = 0) const
    {
        return schedule(start, uint64_t(interval * NSEC_PER_SEC), leeway);
    }
    
    uint64_t data() const {
        return dispatch_source_get_data(DispatchObject);
    }
    
    uint64_t mask() const {
        return dispatch_source_get_mask(DispatchObject);
    }
    
    void cancel() const {
        dispatch_source_cancel(DispatchObject);
    }
    
    bool isCancelled() const {
        return dispatch_source_testcancel(DispatchObject);
    }
    
    auto & resume() const {
        dispatch_resume(DispatchObject);
        return *this;
    }
    
    auto & suspend() const {
        dispatch_suspend(DispatchObject);
        return *this;
    }
    
}; // struct Source
    
} // namespace Dispatch

#endif /* Dispatch_h */
