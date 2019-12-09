//
//  SLHTrimView.m
//  Slash
//
//  Created by Terminator on 2019/11/05.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHTrimView.h"

//#define DEBUG_TRIMVIEW_DRAWING 1
//#define ENABLE_TRIMVIEW_SCROLL_WHEEL 1

#define SLHKnobWidth 10
#define SLHMinWidth  SLHKnobWidth * 2

#define SLHCellHitNone         NSCellHitNone
#define SLHCellHitContentArea  NSCellHitContentArea
#define SLHCellHitLeftKnob     NSCellHitEditableTextArea
#define SLHCellHitRightKnob    NSCellHitTrackableArea

@interface SLHTrimSelectionCell : NSCell {
    NSColor *_strokeColor;
    NSColor *_backgroundColor;
    NSColor *_foregroundColor;
}

@property (nonatomic) NSRect cellFrame;

@end

@implementation SLHTrimSelectionCell

- (instancetype)init
{
    self = [super init];
    if (self) {
        _strokeColor = [NSColor controlShadowColor];
        _backgroundColor = [[NSColor controlBackgroundColor] highlightWithLevel:0.2];
        _foregroundColor = [NSColor selectedControlColor];
    }
    return self;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    
    /* Draw frame */
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(cellFrame, 1, 1) xRadius:3 yRadius:3];
    
    [_strokeColor setStroke];
    [path stroke];
    
    /* Draw body */
    path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(cellFrame, 2, 2) xRadius:3 yRadius:3];

    [_backgroundColor setFill];
    [path fill];
    
    
    /* Draw interior */
    NSRect activeArea = NSInsetRect(cellFrame, SLHKnobWidth, 4);
    path = [NSBezierPath bezierPathWithRoundedRect:activeArea xRadius:2 yRadius:2];

    [_foregroundColor set];
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
    NSTrackingArea *_trackingArea;
    CGFloat _mouseX;
    NSColor *_strokeColor;
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
    _trackingArea = [NSTrackingArea new];
    
    _strokeColor = [NSColor controlShadowColor];
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

#pragma mark Mouse Tracking

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    [self removeTrackingArea:_trackingArea];
    _trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect
                                                 options:NSTrackingInVisibleRect | NSTrackingActiveInKeyWindow | NSTrackingMouseMoved
                                                   owner:self
                                                userInfo:nil];
    [self addTrackingArea:_trackingArea];
}

#pragma mark Events

- (void)mouseMoved:(NSEvent *)event {
    NSPoint event_location = event.locationInWindow;
    NSPoint local_point = [self convertPoint:event_location fromView:nil];
    double value = (local_point.x / (NSWidth(_oldFrame)) * _maxValue);
    self.toolTip = nil;
    self.toolTip = @(value).stringValue;
}

- (void)mouseDown:(NSEvent *)event {
    _hitTestResult = [_selectionCell hitTestForEvent:event inRect:_cellFrame ofView:self];
    _mouseX = event.locationInWindow.x;

    if (_hitTestResult == SLHCellHitNone && event.clickCount < 2) {
        [super mouseDown:event];
    } else if (_hitTestResult & SLHCellHitRightKnob || _hitTestResult & SLHCellHitLeftKnob) {
        [_delegate trimViewMouseDown:self];
        if (_hitTestResult & SLHCellHitLeftKnob) {
            [_delegate trimViewMouseDraggedStartPosition:self];
        } else {
            [_delegate trimViewMouseDraggedEndPosition:self];
        }
    }
}

- (void)mouseUp:(NSEvent *)event {
    
    if (_hitTestResult & SLHCellHitRightKnob || _hitTestResult & SLHCellHitLeftKnob) {
        [_delegate trimViewMouseUp:self];
    }
    
    if (event.clickCount == 2) {
        NSPoint event_location = event.locationInWindow;
        NSPoint local_point = [self convertPoint:event_location fromView:nil];
        double value = (local_point.x / (NSWidth(_oldFrame)) * _maxValue);
        
        if (_hitTestResult == SLHCellHitNone) {
            if (value < _startValue) {
                self.startValue = value;
                 [self updateValue:@(_startValue) forBinding:@"startValue"];
                return;
            }
            
            self.endValue = value;
            [self updateValue:@(_endValue) forBinding:@"endValue"];
            return;
        }
        
        if (_hitTestResult & SLHCellHitContentArea &&
          !(_hitTestResult & SLHCellHitLeftKnob)   &&
          !(_hitTestResult & SLHCellHitRightKnob)) {
   
            double distanceToStart = value - _startValue;
            double distanceToEnd = _endValue - value;
            
            if (distanceToStart < distanceToEnd) {
                self.startValue = value;
                 [self updateValue:@(_startValue) forBinding:@"startValue"];
                return;
            }
            
            self.endValue = value;
            [self updateValue:@(_endValue) forBinding:@"endValue"];
            return;
        }
        
    }
    [super mouseUp:event];
}

- (void)mouseDragged:(NSEvent *)event {
    
    if (_hitTestResult & SLHCellHitLeftKnob ) {
        CGFloat newMouseX = event.locationInWindow.x;
        CGFloat deltaX = ((newMouseX - _mouseX) / (NSWidth(_maxSelectionFrame)) * _maxValue);
        double candidate = _startValue + deltaX;
        self.startValue = candidate;
        [self updateValue:@(_startValue) forBinding:@"startValue"];
        
        _mouseX = newMouseX;
        [_delegate trimViewMouseDraggedStartPosition:self];
        return;
    }
    
    if (_hitTestResult & SLHCellHitRightKnob) {
        CGFloat newMouseX = event.locationInWindow.x;
        CGFloat deltaX = ((newMouseX - _mouseX) / NSWidth(_maxSelectionFrame) * _maxValue);
        double candidate = _endValue + deltaX;
        self.endValue = candidate;
        [self updateValue:@(_endValue) forBinding:@"endValue"];
        _mouseX = newMouseX;
        [_delegate trimViewMouseDraggedEndPosition:self];
        return;
    }
    [self.superview mouseDragged:event];
}

#if ENABLE_TRIMVIEW_SCROLL_WHEEL

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

#endif

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

    [_strokeColor set];
    NSBezierPath *path;
    path = [NSBezierPath bezierPathWithRoundedRect:_oldFrame xRadius:3 yRadius:3];
    [path stroke];
    
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

    _maxValue = 1;
    _endValue = _maxValue;
    _startValue = 0;
    _minValue = 0;

    [super prepareForReuse];
}

@end

