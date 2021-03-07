//
//  SLTEncoder.h
//  Slash
//
//  Created by Terminator on 2020/07/30.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLTEncoder : NSObject

- (void)startEncoding:(NSArray<NSArray<NSString*>*>*)arguments
                using:(void(^)(NSString *status,
                               int64_t encodedFrames))updateHandler
                 done:(void(^)(NSString *log,
                               NSError *_Nullable error))exitHandler;

@property (readonly) BOOL paused;
@property (readonly) BOOL cancelled;
@property (readonly) BOOL executing;
@property (readonly) BOOL finished;

- (void)pause;
- (void)resume;
- (void)cancel;

@property (readonly) NSString *log;

@end

NS_ASSUME_NONNULL_END
