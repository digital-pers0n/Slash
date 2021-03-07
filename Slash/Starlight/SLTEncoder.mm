//
//  SLTEncoder.m
//  Slash
//
//  Created by Terminator on 2020/07/30.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLTEncoder.h"
#import "SLTTask.h"

#import "Argv.h"
#import "Encoder.h"

@interface SLTEncoder () {
    SL::Spawn _ffmpeg;
    Dispatch::Queue _encoderQueue;
    NSMutableString *_log;
    NSMutableArray *_passes;
}

@property BOOL paused;
@property BOOL cancelled;
@property BOOL executing;
@property BOOL finished;

@end

[[clang::objc_direct_members]]
@implementation SLTEncoder

- (instancetype)init {
    self = [super init];
    if (self) {
        _encoderQueue = Dispatch::CreateSerialQueue("org.slash.encoder.queue");
        _log = [NSMutableString new];
    }
    return self;
}

- (NSString *)log {
    return (!self.finished || !self.cancelled) ? @"(Not Available)" : _log;
}

- (void)pause {
#if DEBUG
    if (self.paused) {
        NSLog(@"Encoder is already paused. Ignoring");
        return;
    }
    
    if (!self.executing) {
        NSLog(@"Nothing is being encoded.");
        return;
    }
#else
    NSAssert(!self.paused, @"Encoder is already paused.");
    NSAssert(self.executing, @"Nothing to pause.");
#endif
    
    if (!_ffmpeg.isRunning()) return;
    if (_ffmpeg.suspend() != 0) return;
    self.paused = YES;
}

- (void)resume {
#if DEBUG
    if (!self.paused) {
        NSLog(@"Encoder was already resumed. Ignoring");
        return;
    }
    
    if (!self.executing) {
        NSLog(@"Nothing is being encoded.");
        return;
    }
#else
    NSAssert(self.paused, @"Encoder is not paused.");
    NSAssert(self.executing, @"Nothing to resume.");
#endif
    
    if (!_ffmpeg.isRunning()) return;
    if (_ffmpeg.resume() != 0) return;;
    self.paused = NO;
}

- (void)cancel {
#if DEBUG
    if (self.cancelled) {
        NSLog(@"Encoder was already cancelled. Ignoring");
        return;
    }
    
    if (!self.executing) {
        NSLog(@"Nothing is being encoded.");
        return;
    }
#else
    NSAssert(!self.cancelled, @"Encoder was already cancelled.");
    NSAssert(self.executing, @"Nothing to cancel.");
#endif
    
    if (!_ffmpeg.isRunning()) return;
    _ffmpeg.resume(); // suspended processes may become zombies if terminated
    if (_ffmpeg.terminate() != 0) return;
    self.cancelled = YES;
    self.executing = NO;
}

- (void)startEncoding:(NSArray<NSArray<NSString*>*>*)arguments
                using:(void(^)(NSString *status,
                               int64_t encodedFrames))updateHandler
                 done:(void(^)(NSString *log,
                               NSError *_Nullable error))exitHandler
{
    NSAssert(!self.executing, @"Encoding is already in progress.");
    NSAssert(arguments.count, @"Arguments array is empty.");

    _finished = _cancelled = _paused = NO;
    [self encode:arguments.mutableCopy
             log:[NSMutableData new] using:updateHandler done:exitHandler];
}


- (void)encode:(NSMutableArray<NSArray<NSString*>*>*)args
           log:(NSMutableData *)data
         using:(void(^)(NSString *status,
                        int64_t encodedFrames))updateHandler
          done:(void(^)(NSString *log,
                        NSError *_Nullable error))exitHandler
{
    SL::Encoder { SL::Argv(args.firstObject), _encoderQueue,
        [&] (const SL::Spawn &encoder) { // start
            _ffmpeg = encoder;
            self.executing = YES;
        },
        [=] (const char *text, size_t len, int64_t nFrames) { // status update
            const auto s = [[NSString alloc] initWithBytes:text length:len
                                             encoding:NSUTF8StringEncoding];
            updateHandler(s, nFrames);
        },
        [=] (const char *text, size_t len) { // log update
            [data appendBytes:text length:len];
        },
        [=] (int exitStatus) { // exit
            NSError *e = nil;
            if (_cancelled) {
                goto done;
            }
            
            self.executing = NO;
            if (WEXITSTATUS(exitStatus) != 0) {
                //TODO: create NSError
                goto done;
            }
            
            [args removeObjectAtIndex:0];
            if (args.count) {
                const char str[] = "\n ======= Encoding Next Pass ======= \n";
                [data appendBytes:str length:sizeof(str) - 1];
                [self encode:args log:data using:updateHandler done:exitHandler];
                return;
            }
            
        done:
            self.finished = YES;
            NSString *result;
            [NSString stringEncodingForData:data encodingOptions:nil
                            convertedString:&result usedLossyConversion:nil];
            [_log setString:result ?:
                            @"Error: cannot determine the string encoding."];
            exitHandler(_log, e);
        },
        [&](int errorCode){ // fail
            auto dict = @{ NSFilePathErrorKey : args.firstObject };
            auto e = [NSError errorWithDomain:NSPOSIXErrorDomain
                                         code:errorCode userInfo:dict];
            self.finished = YES;
            exitHandler(self.log, e);
        }
    }; // Encoder
}

@end
