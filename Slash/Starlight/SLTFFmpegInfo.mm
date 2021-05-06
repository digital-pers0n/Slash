//
//  SLTFFmpegInfo.m
//  Slash
//
//  Created by Terminator on 2020/11/2.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLTFFmpegInfo.h"

#import "ASPrint.h"
#import "Popen.h"

#import "MPVKitDefines.h"

OBJC_DIRECT_MEMBERS
@implementation SLTFFmpegInfo

- (nullable instancetype)initWithPath:(NSString *)ffmpegPath
                              handler:(void(^)(NSError*))errorBlock
{
    NSAssert(ffmpegPath, @"FFmpeg path cannot be nil.");
    if (!(self = [super init])) return nil;
    
    auto ff = ffmpegPath.UTF8String;
    NSError *e;
    auto didFail = [&](NSString *msg, NSString *sug) {
        e = [self errorWithMessage:msg suggestion:sug];
    };
    
    SL::Popen { SL::ASPrint { "'%s' -version && '%s' -hide_banner -encoders "
           "&& '%s' -hide_banner -filters", ff, ff, ff }, SL::Popen::Mode::Read,
    [&](FILE *ptr) {
        constexpr size_t bufSize = 512;
        char buf[bufSize + 1]{};
        
        auto ifNot = [&](char c, auto action) {
            return buf[0] == c ? false : [&]{ action(); return true; }();
        };
        auto nextLine = [&]{ return fgets(buf, bufSize, ptr); };
        auto contains = [&](const char *str) { return strstr(buf, str); };
        auto forEachLine = [&](auto body) { while (nextLine() && body()) {} };
        auto parse = [&](const char *name, auto action) {
            if (contains(name)) {
                nextLine();
                char *canContinue{};
                while (contains("=") && (canContinue = nextLine())) {}
                if (!canContinue) return;
                action();
                forEachLine(action);
            }
        };
        auto parseBuildInfo = [&](auto action) {
            forEachLine([&]{ return ifNot('E', action); });
        };
        auto parseEncoders = [&](auto action) {
            parse("Encoders:", [&]{ return ifNot('F', action); });
        };
        auto parseFilters = [&](auto action) {
            parse("Filters:", [&]{
                action();
                return true;
            });
        };
        auto sort = [](NSArray *obj) {
            return [obj sortedArrayUsingSelector:@selector(compare:)];
        };
        auto cleanup = [&]{ return pclose(ptr); };
        auto fail = [&](NSString *msg) {
            didFail(msg, @(buf));
            return cleanup();
        };
        
        nextLine();
        if (!contains("ffmpeg version ")) {
            return fail(@"Failed to find any version information.");
        }
        _versionString = @(buf);
        
        auto bc = [NSMutableString new];
        parseBuildInfo([&]{ [bc appendString:@(buf)]; });
        
        if (!bc.length) {
            return fail(@"Failed to find any build configuration information.");
        }
        _buildConfigurationString = bc;

        auto audio = [NSMutableArray new];
        auto video = [NSMutableArray new];
        auto subs = [NSMutableArray new];
        
        parseEncoders([&]{
            auto items = [@(buf) componentsSeparatedByString:@" "];
            if (items.count < 3) return;
            auto addTo = [&](NSMutableArray *arg) {
                [arg addObject:[items objectAtIndex:2]];
            };
            switch (buf[1]) {
                case 'V': addTo(video); break;
                case 'A': addTo(audio); break;
                case 'S': addTo(subs); break;
            }
        });
        
        if (!(audio.count || video.count || subs.count)) {
            return fail(@"Failed to find any encoders.");
        }

        auto total = [[NSMutableArray alloc] initWithArray:video];
        [total addObjectsFromArray:audio];
        [total addObjectsFromArray:subs];
        
        _videoEncoders = sort(video);
        _audioEncoders = sort(audio);
        _subtitlesEncoders = sort(subs);
        _encoders = sort(total);
        [video removeAllObjects];
        [audio removeAllObjects];
        [total removeAllObjects];
        
        parseFilters([&]{
            auto items = [@(buf) componentsSeparatedByString:@" "];
            if (items.count < 3) return;
            
            auto filter = [items objectAtIndex:2];
            [total addObject:filter];
            
            if (contains(" A->A ")) {
                [audio addObject:filter];
            } else if (contains(" V->V ")) {
                [video addObject:filter];
            }
        });

        if (!total.count) {
            return fail(@"Failed to find any filters.");
        }
        
        _videoFilters = sort(video);
        _audioFilters = sort(audio);
        _filters = sort(total);
        
        return cleanup();
    }, [&]{ didFail(@"Failed to launch ffmpeg.", @"Internal error"); }}; //Popen
    
    if (e) {
        errorBlock(e);
        return nil;
    }
    
    _path = ffmpegPath.copy;
    
    return self;
}

- (BOOL)sortedArray:(NSArray<NSString*> *)arr contains:(NSString *)obj {
    const auto flag = NSBinarySearchingFirstEqual;
    const auto cmp = ^(NSString *_Nonnull a, NSString *_Nonnull b) {
        return [a compare:b options:0 range:{0, a.length} locale:nil];
    };
    return ([arr indexOfObject:obj inSortedRange:{ 0, arr.count } options:flag
               usingComparator:cmp] != NSNotFound);
}

- (BOOL)hasFilter:(NSString *)name {
    NSAssert(name, @"Filter name cannot be nil");
    return [self sortedArray:_filters contains:name];
}

- (BOOL)hasEncoder:(NSString *)name {
    NSAssert(name, @"Encoder name cannot be nil");
    return [self sortedArray:_encoders contains:name];
}

- (NSError *)errorWithMessage:(NSString *)msg suggestion:(NSString *)sug {
    id dict = @{ NSLocalizedDescriptionKey : msg,
                 NSLocalizedRecoverySuggestionErrorKey : sug };
    return [NSError errorWithDomain:NSCocoaErrorDomain
                               code:NSExecutableLoadError userInfo:dict];
}

@end
