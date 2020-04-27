//
//  SLHSliderCell.m
//  Slash
//
//  Created by Terminator on 2019/10/29.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHSliderCell.h"

@interface SLHSliderCell () {
    NSMutableDictionary <NSString *, NSDictionary *> *_bindingInfo;
}

@end

@implementation SLHSliderCell

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _markColor = [NSColor blackColor];
        _selectionColor = [NSColor systemYellowColor];
        _bindingInfo = [NSMutableDictionary new];
    }
    return self;
}

#pragma mark - KVB

+ (void)initialize {
    if (self == [SLHSliderCell class]) {
        [self exposeBinding:@"inMark"];
        [self exposeBinding:@"outMark"];
    }
}

static char inMarkKVOContext;
static char outMarkKVOContext;

- (void)bind:(NSString *)binding
    toObject:(id)observable
 withKeyPath:(NSString *)keyPath
     options:(NSDictionary<NSString *,id> *)options {
    
    void *context = nil;
    if ([binding isEqualToString:@"inMark"]) {
        context = &inMarkKVOContext;
    } else if ([binding isEqualToString:@"outMark"]) {
        context = &outMarkKVOContext;
    }
    if (context) {
        if (_bindingInfo[binding]) {
            [self unbind:binding];
        }
        [observable addObserver:self
                     forKeyPath:keyPath
                        options:NSKeyValueObservingOptionNew
                        context:context];
        NSDictionary *bindingsData = @{ NSObservedObjectKey: observable,
                                        NSObservedKeyPathKey: keyPath.copy,
                                        NSOptionsKey: options ? options.copy : [NSNull null] };
        [_bindingInfo setObject:bindingsData forKey:binding];
    } else {
        [super bind:binding toObject:observable withKeyPath:keyPath options:options];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    NSString *binding = nil;
    if (context == &inMarkKVOContext) {
        binding = @"inMark";
    } else if (context == &outMarkKVOContext) {
        binding = @"outMark";
    }
    if (binding) {
        id value = change[NSKeyValueChangeNewKey];
        if (value) {
            [self setValue:value forKey:binding];
        }
    } else {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
    
}

- (void)unbind:(NSString *)binding {
    NSDictionary *info = _bindingInfo[binding];
    if (info) {
        [info[NSObservedObjectKey] removeObserver:self
                                       forKeyPath:info[NSObservedKeyPathKey]];
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

#pragma mark - Overrides

- (BOOL)startTrackingAt:(NSPoint)startPoint inView:(NSView *)controlView {
    
    BOOL value = [super startTrackingAt:startPoint inView:controlView];
    [_delegate sliderCellMouseDown:self];
    return value;
}

- (BOOL)continueTracking:(NSPoint)lastPoint at:(NSPoint)currentPoint inView:(NSView *)controlView {
    
    BOOL value = [super continueTracking:lastPoint at:currentPoint inView:controlView];
    [_delegate sliderCellMouseDragged:self];
    return value;
}

- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)stopPoint inView:(NSView *)controlView mouseIsUp:(BOOL)flag {
    
    [super stopTracking:lastPoint at:stopPoint inView:controlView mouseIsUp:flag];
    [_delegate sliderCellMouseUp:self];
}

- (void)drawBarInside:(NSRect)rect flipped:(BOOL)flipped {
    [super drawBarInside:rect flipped:flipped];
    double maxValue = self.maxValue;
    if ( _outMark == 0 || maxValue == 0) { return; }
    CGFloat inX = round(_inMark / maxValue * NSWidth(rect));
    CGFloat outX = round(_outMark / maxValue * NSWidth(rect));
    
    rect.origin.y += 1;
    rect.size.height -= 2;
    
    rect.size.width = outX - inX;
    rect.origin.x = inX;
    
    [_selectionColor set];
    NSRectFill(rect);
    
    rect.size.width = 1;
    [_markColor set];
    NSRectFill(rect);
    
    rect.origin.x = outX;
    NSRectFill(rect);
}

@end
