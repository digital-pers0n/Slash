//
//  SLHVolumeButton.m
//  Slash
//
//  Created by Terminator on 2020/02/10.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLHVolumeButton.h"

@interface SLHVolumeButton () {
    NSMutableDictionary *_bindingInfo;
}
@end

@implementation SLHVolumeButton

- (void)scrollWheel:(NSEvent *)event {
    if (!self.enabled) {
        return;
    }
    
    NSDictionary *info = [self infoForBinding:NSValueBinding];
    if (info) {
        CGFloat deltaY = -event.scrollingDeltaY;
        if (deltaY > 0 && deltaY < 1) {
            deltaY = 1;
        } else if (deltaY > -1 && deltaY < 0) {
            deltaY = -1;
        }
        id observable = info[NSObservedObjectKey];
        NSString *keyPath =  info[NSObservedKeyPathKey];
        NSInteger value = [[observable valueForKeyPath:keyPath] integerValue] + deltaY;

        if (value >= _minValue && value <= _maxValue) {
            NSNumber *volume = @(value);
            [observable setValue:volume forKeyPath: keyPath];
            self.toolTip = nil;
            self.toolTip = volume.stringValue;
        }
        
    }
}

- (void)awakeFromNib {
    _bindingInfo = [NSMutableDictionary new];
}

#pragma mark - Partial Key Value Bindings

+ (void)initialize {
    if (self == [SLHVolumeButton class]) {
        [self exposeBinding:NSValueBinding];
    }
}

- (void)bind:(NSString *)binding
    toObject:(id)observable
 withKeyPath:(NSString *)keyPath
     options:(NSDictionary<NSString *,id> *)options {
    
    if ([binding isEqualToString:NSValueBinding]) {
        if (_bindingInfo[binding]) {
            [self unbind:binding];
        }
        
        NSDictionary *bindingsData = @{
                                       NSObservedObjectKey     : observable,
                                       NSObservedKeyPathKey    : keyPath.copy,
                                       NSOptionsKey            : options ? options.copy : [NSNull null]
                                       };
        _bindingInfo[binding] = bindingsData;

    } else {
        [super bind:binding
           toObject:observable
        withKeyPath:keyPath
            options:options];
    }
}

- (void)unbind:(NSString *)binding {
    NSDictionary *info = _bindingInfo[binding];
    if (info) {
        [_bindingInfo removeObjectForKey:binding];
    } else {
        [super unbind:binding];
    }
}

- (NSDictionary<NSString *,id> *)infoForBinding:(NSString *)binding {
    NSDictionary *info = _bindingInfo[binding];
    if (info) {
        return info;
    }
    return [super infoForBinding:binding];
}

- (Class)valueClassForBinding:(NSString *)binding {
    if (_bindingInfo[binding]) {
        return [NSNumber class];
    }
    return [super valueClassForBinding:binding];
}

@end
