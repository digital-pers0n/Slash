//
//  SLHTrimView.m
//  Slash
//
//  Created by Terminator on 2019/11/05.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHTrimView.h"

//#define DEBUG_TRIMVIEW_DRAWING 1

#define SLHKnobWidth 10
#define SLHMinWidth  SLHKnobWidth * 2

#define SLHCellHitNone         NSCellHitNone
#define SLHCellHitContentArea  NSCellHitContentArea
#define SLHCellHitLeftKnob     NSCellHitEditableTextArea
#define SLHCellHitRightKnob    NSCellHitTrackableArea

@interface SLHTrimSelectionCell : NSCell

@property (nonatomic) NSRect cellFrame;

@end

@implementation SLHTrimSelectionCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    
    /* Draw frame */
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(cellFrame, 1, 1) xRadius:3 yRadius:3];
    
    [[NSColor controlShadowColor] setStroke];
    [path stroke];
    
    /* Draw body */
    path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(cellFrame, 2, 2) xRadius:3 yRadius:3];

    [[[NSColor controlBackgroundColor] highlightWithLevel:0.2] setFill];
    [path fill];
    
    
    /* Draw interior */
    NSRect activeArea = NSInsetRect(cellFrame, SLHKnobWidth, 4);
    path = [NSBezierPath bezierPathWithRoundedRect:activeArea xRadius:2 yRadius:2];

    [[NSColor windowBackgroundColor] set];
    [path fill];

}

- (NSCellHitResult)hitTestForEvent:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView {
    NSPoint event_location = event.locationInWindow;
    NSPoint local_point = [controlView convertPoint:event_location fromView:nil];
    if ([controlView mouse:local_point inRect:cellFrame]) {
        NSRect leftKnobRect = leftKnobFrame(cellFrame);
        if ([controlView mouse:local_point inRect:leftKnobRect]) {
            return SLHCellHitContentArea | SLHCellHitLeftKnob;
        }
        
        NSRect rightKnobRect = rightKnobFrame(cellFrame);
        if ([controlView mouse:local_point inRect:rightKnobRect]) {
            return SLHCellHitContentArea | SLHCellHitRightKnob;
        }
        return SLHCellHitContentArea;
    }
    
    return SLHCellHitNone;
}

static inline NSRect leftKnobFrame(NSRect cellFrame) {
    return NSMakeRect(NSMinX(cellFrame), 0, SLHKnobWidth, NSHeight(cellFrame));
}

static inline NSRect rightKnobFrame(NSRect cellFrame) {
    return NSMakeRect(NSMaxX(cellFrame) - SLHKnobWidth, 0, SLHKnobWidth, NSHeight(cellFrame));
}


@end

#pragma mark -
#pragma mark **** SLHTrimView ****

@interface SLHTrimView () {
    double _startValue;
    double _endValue;
}

@property SLHTrimSelectionCell *selectionCell;
@property (nonatomic) NSRect cellFrame;
@property (nonatomic) NSRect interiorFrame;
@property (nonatomic) NSRect maxSelectionFrame;
@property (nonatomic) NSRect oldFrame;
@property (nonatomic) NSCellHitResult hitTestResult;

@property (nonatomic) NSMutableDictionary <NSString *, NSDictionary *> *bindingInfo;

@end



@implementation SLHTrimView

#pragma mark - Initialization

- (void)setUp {
    _selectionCell = [[SLHTrimSelectionCell alloc] init];
    _oldFrame = self.bounds;
    _maxSelectionFrame = NSInsetRect(_oldFrame, SLHKnobWidth, 0);
    self.maxValue = 1;
    self.endValue = _maxValue;
    _cellFrame = _oldFrame;
    self.minValue = 0;
    _bindingInfo = [NSMutableDictionary new];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setUp];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setUp];
    }
    return self;
}

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUp];
    }
    return self;
}

+ (void)initialize {
    if (self == [SLHTrimView class]) {
        // Useless.
        [self exposeBinding:@"startValue"];
        [self exposeBinding:@"endValue"];
        [self exposeBinding:@"maxValue"];
        [self exposeBinding:@"minValue"];
    }
}

#pragma mark - Cocoa Bindings

static char startValueKVOContext;
static char endValueKVOContext;
static char maxValueKVOContext;
static char minValueKVOContext;

- (void)bind:(NSString *)binding toObject:(id)observable withKeyPath:(NSString *)keyPath options:(NSDictionary<NSString *,id> *)options {
    void *context = nil;
    if ([binding isEqualToString:@"startValue"]) {
        context = &startValueKVOContext;
    } else if ([binding isEqualToString:@"endValue"]) {
        context = &endValueKVOContext;
    } else if ([binding isEqualToString:@"maxValue"]) {
        context = &maxValueKVOContext;
    } else if ([binding isEqualToString:@"minValue"]) {
        context = &minValueKVOContext;
    }
    
    if (context) {
        if (_bindingInfo[binding]) {
            [self unbind:binding];
        }
        [observable addObserver:self forKeyPath:keyPath options:0 context:context];
        
        NSDictionary *bindingsData = @{ NSObservedObjectKey: observable,
                                        NSObservedKeyPathKey: keyPath.copy,
                                        NSOptionsKey: options ? options.copy : NSNull.null};
        [_bindingInfo setObject:bindingsData forKey:binding];
        
    } else {
        [super bind:binding toObject:observable withKeyPath:keyPath options:options];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSString *binding = nil;
    if (context == &startValueKVOContext) {
        binding = @"startValue";
    } else if (context == &endValueKVOContext) {
        binding = @"endValue";
    } else if (context == &maxValueKVOContext) {
        binding = @"maxValue";
    } else if (context == &minValueKVOContext) {
        binding = @"minValue";
    }
    
    if (binding) {
        id value = [object valueForKeyPath:keyPath];
        if (value != NSNotApplicableMarker && value != NSNoSelectionMarker) {
            [self setValue:value forKey:binding];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)unbind:(NSString *)binding {
    NSDictionary *info = _bindingInfo[binding];
    if (info) {
        [info[NSObservedObjectKey] removeObserver:self forKeyPath: info[NSObservedKeyPathKey]];
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
    
    NSDictionary *info = _bindingInfo[binding];
    if (info) {
        return [NSNumber class];
    }
    return [super valueClassForBinding:binding];
}

- (void)updateValue:(id)value forBinding:(NSString *)binding {
    NSDictionary *info = _bindingInfo[binding];
    if (info) {
        [info[NSObservedObjectKey] setValue: value forKeyPath: info[NSObservedKeyPathKey]];
    }
}

#pragma mark - Overrides
#pragma mark Properties

- (void)setStartValue:(double)startValue {
    if (startValue <= _endValue) {
        
        if (startValue <= _minValue) {
            startValue = _minValue;
        }
        
        _startValue = startValue;
        
        [self setNeedsDisplay:YES];
    }
}

- (void)setEndValue:(double)endValue {
    
    if (endValue  >= _startValue) {
        
        if (endValue >= _maxValue) {
            endValue = _maxValue;
        }
        
        _endValue = endValue;
        
        [self setNeedsDisplay:YES];
    }
}

#pragma mark Events

- (void)mouseDown:(NSEvent *)event {
    _hitTestResult = [_selectionCell hitTestForEvent:event inRect:_cellFrame ofView:self];
    if (_hitTestResult == SLHCellHitNone) {
        [self.superview mouseDown:event];
    }
}

- (void)scrollWheel:(NSEvent *)event {
    
    NSCellHitResult result = [_selectionCell hitTestForEvent:event inRect:_cellFrame ofView:self];
    
    if (result & SLHCellHitLeftKnob) {
        double deltaY = -event.scrollingDeltaY / NSWidth(_maxSelectionFrame) * _maxValue;
        self.startValue = _startValue + deltaY;
        [self updateValue:@(_startValue) forBinding:@"startValue"];
        return;
    }
    if (result & SLHCellHitRightKnob) {
        double deltaY = -event.scrollingDeltaY / NSWidth(_maxSelectionFrame) * _maxValue;
        self.endValue = _endValue + deltaY;
        [self updateValue:@(_endValue) forBinding:@"endValue"];
        return;
    }
    [self.superview scrollWheel:event];
}

- (void)mouseDragged:(NSEvent *)event {
    
    if (_hitTestResult & SLHCellHitLeftKnob ) {
        CGFloat deltaX = (event.deltaX / (NSWidth(_maxSelectionFrame)) * _maxValue);
        double candidate = _startValue + deltaX;
        self.startValue = candidate;
        [self updateValue:@(_startValue) forBinding:@"startValue"];
        return;
    }
    
    if (_hitTestResult & SLHCellHitRightKnob) {
        CGFloat deltaX = (event.deltaX / NSWidth(_maxSelectionFrame) * _maxValue);
        double candidate = _endValue + deltaX;
        self.endValue = candidate;
        [self updateValue:@(_endValue) forBinding:@"endValue"];
        return;
    }
    [self.superview mouseDragged:event];
}

#pragma mark Frame

- (void)setFrame:(NSRect)frame {
    
    double scale = NSWidth(frame) / NSWidth(_oldFrame);
    double start = NSMinX(_cellFrame) * scale;
    
    _cellFrame.origin.x = round(start);
    
    double end = NSWidth(_cellFrame) * scale;
    if (end > SLHMinWidth ) {
        
        _cellFrame.size.width = round(end);
        
    }
    _cellFrame.size.height = NSHeight(frame);
    
    _oldFrame.size = frame.size;
    _maxSelectionFrame.size = NSInsetRect(_oldFrame, SLHKnobWidth, 0).size;
    [super setFrame:frame];
}

#pragma mark Draw

- (void)drawRect:(NSRect)dirtyRect {

    CGFloat startMark = (_startValue) / _maxValue * NSWidth(_maxSelectionFrame);
    CGFloat endMark = _endValue / _maxValue * NSWidth(_maxSelectionFrame);
    _cellFrame.origin.x = round(startMark);
    _cellFrame.size.width = round(endMark) - NSMinX(_cellFrame) + SLHMinWidth ;
    
    [_selectionCell drawWithFrame:_cellFrame inView:self];

#ifdef DEBUG_TRIMVIEW_DRAWING
    NSRect interiorFrame = NSInsetRect(_cellFrame, SLHKnobWidth, 0);
    [[NSColor redColor] set];
    NSFrameRect(interiorFrame);
    [[NSColor greenColor] set];
    NSFrameRect(_maxSelectionFrame);
    [[NSColor purpleColor] set];
    NSFrameRect(_cellFrame);
    [[NSColor yellowColor] set];
    NSFrameRect(self.bounds);
#endif

}

#pragma mark NSTableView Support

- (void)prepareForReuse {
    [_bindingInfo.copy enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary * _Nonnull obj, BOOL * _Nonnull stop) {
        [self unbind:key];
    }];
    self.maxValue = 1;
    self.endValue = _maxValue;
    self.minValue = 0;
    [super prepareForReuse];
}

@end

