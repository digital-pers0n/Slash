//
//  SLHTrimView.m
//  Slash
//
//  Created by Terminator on 2019/11/05.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHTrimView.h"
@import QuartzCore.CAShapeLayer;

//#define DEBUG_TRIMVIEW_DRAWING 1
//#define ENABLE_TRIMVIEW_SCROLL_WHEEL 1
#define ENABLE_TRIMVIEW_DOUBLE_CLICK 0

#define SLHKnobWidth SLHTrimViewHandleThickness
#define SLHMinWidth  SLHKnobWidth * 2

#define SLHCellHitNone         NSCellHitNone
#define SLHCellHitContentArea  NSCellHitContentArea
#define SLHCellHitLeftKnob     NSCellHitEditableTextArea
#define SLHCellHitRightKnob    NSCellHitTrackableArea


inline NSRect
NSOffsetRect(NSRect aRect, CGFloat dx, CGFloat dy)
{
    NSRect rect = aRect;
    
    rect.origin.x += dx;
    rect.origin.y += dy;
    return rect;
}

inline NSRect
NSInsetRect(NSRect aRect, CGFloat dX, CGFloat dY)
{
    NSRect rect;
    
    rect = NSOffsetRect(aRect, dX, dY);
    rect.size.width -= (2 * dX);
    rect.size.height -= (2 * dY);
    return rect;
}


#pragma mark -
#pragma mark **** SLHTrimSelectionCell ****

@interface SLHTrimSelectionCell : NSObject {
    @package
    CAShapeLayer *_controlLayer;
    CAShapeLayer *_backgroundLayer;
}

@property (nonatomic) NSRect cellFrame;
@property (nonatomic) CAShapeLayer *backgroundLayer;

@end

@implementation SLHTrimSelectionCell

- (instancetype)init
{
    self = [super init];
    if (self) {
        _controlLayer = [CAShapeLayer new];
        _controlLayer.fillColor = [[NSColor systemYellowColor] CGColor];
        _controlLayer.fillRule = kCAFillRuleEvenOdd;
        _controlLayer.lineWidth = 1;
        _controlLayer.shadowColor = [[NSColor shadowColor] CGColor];
        _controlLayer.shadowOpacity = 0.5;
        _controlLayer.shadowOffset = NSMakeSize(0, -1);
        _controlLayer.shadowRadius = 0.5;
        
        _backgroundLayer = [CAShapeLayer new];
        _backgroundLayer.fillRule = kCAFillRuleEvenOdd;
        _backgroundLayer.fillColor = [[NSColor colorWithWhite:0.0
                                                        alpha:0.5] CGColor];
        [_backgroundLayer addSublayer:_controlLayer];
        
    }
    return self;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    
    NSRect hole = NSInsetRect(cellFrame, SLHKnobWidth, 4);
    
    CGMutablePathRef ref = CGPathCreateMutable();

    CGPathAddRoundedRect(ref, nil, NSInsetRect(cellFrame, 1, 1), 2, 2);
    CGPathAddRect(ref, nil, hole);

    _controlLayer.path = ref;
    
    CGPathRelease(ref);
    
    ref = CGPathCreateMutable();
    CGPathAddRoundedRect(ref, nil, NSInsetRect(controlView.bounds, SLHKnobWidth, 1), 2, 2);
    CGPathAddRect(ref, nil, hole);
    _backgroundLayer.path = ref;
    
    CGPathRelease(ref);

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
#pragma mark **** SLHTrimSelectionSimpleCell ****

@interface SLHTrimSelectionSimpleCell : SLHTrimSelectionCell {
    __weak CAShapeLayer *_frameLayer;
}
@end

@implementation SLHTrimSelectionSimpleCell

- (instancetype)init
{
    self = [super init];
    if (self) {
        _controlLayer.fillRule = kCAFillRuleNonZero;
        _backgroundLayer.fillRule = kCAFillRuleNonZero;
        CAShapeLayer * frameLayer = [CAShapeLayer new];
        frameLayer.fillRule = kCAFillRuleNonZero;
        frameLayer.fillColor = _backgroundLayer.fillColor;
        [_backgroundLayer addSublayer:frameLayer];
        _frameLayer = frameLayer;
    }
    return self;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    
    CGMutablePathRef mutablePath;
    const CGFloat cellHeight = NSHeight(cellFrame);
    const CGFloat barWidth = 2.0;
    const CGFloat barHeight = (cellHeight * 0.5);
    
    CGRect bar = CGRectMake(NSMinX(cellFrame) + SLHKnobWidth - barWidth,
                            ((cellHeight - barHeight) * 0.5),
                            barWidth, barHeight);
    mutablePath = CGPathCreateMutable();
    CGPathAddRect(mutablePath, nil, bar);
    
    bar.origin.x = NSMaxX(cellFrame) - SLHKnobWidth;
    CGPathAddRect(mutablePath, nil, bar);
    _frameLayer.path = mutablePath;
    CGPathRelease(mutablePath);
    
    CGPathRef path;
    path = CGPathCreateWithRoundedRect(NSInsetRect(cellFrame, 1, 1), 4, 4, nil);
    _controlLayer.path = path;
    CGPathRelease(path);
    
    path = CGPathCreateWithRoundedRect(controlView.bounds, 4, 4, nil);
    _backgroundLayer.path = path;
    CGPathRelease(path);
}

@end

#pragma mark -
#pragma mark **** SLHTrimView ****

@interface SLHTrimView () {
    double _startValue;
    double _endValue;
    NSTrackingArea *_trackingArea;
    CGFloat _mouseX;
    SLHTrimViewStyle _style;
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
    self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawDuringViewResize;
    self.wantsLayer = YES;
    [self.layer addSublayer:_selectionCell.backgroundLayer];
    _oldFrame = self.bounds;
    _maxSelectionFrame = NSInsetRect(_oldFrame, SLHKnobWidth, 0);
    self.maxValue = 1;
    self.endValue = _maxValue;
    _cellFrame = _oldFrame;
    self.minValue = 0;
    _bindingInfo = [NSMutableDictionary new];
    _trackingArea = [NSTrackingArea new];
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

#pragma mark - Methods

- (void)reset {
    _maxValue = 1;
    _endValue = _maxValue;
    _startValue = 0;
    _minValue = 0;
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

- (NSRect)selectionFrame {
    return NSInsetRect(_cellFrame, SLHKnobWidth, 0);
}

- (void)setStyle:(SLHTrimViewStyle)style {
    if (_style == style) { return; }
    [_selectionCell.backgroundLayer removeFromSuperlayer];
    switch (style) {
        case SLHTrimViewStyleSimple:
            _selectionCell = [[SLHTrimSelectionSimpleCell alloc] init];
            break;
            
        case SLHTrimViewStyleFrame:
        default:
            _selectionCell = [[SLHTrimSelectionCell alloc] init];
            break;
    }
    [self.layer addSublayer:_selectionCell.backgroundLayer];
    _style = style;
}

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
    NSTrackingAreaOptions trackingOptions =
    NSTrackingInVisibleRect | NSTrackingActiveInKeyWindow | NSTrackingMouseMoved;
    
    _trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect
                                                 options:trackingOptions
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
    if (_formatter) {
        self.toolTip = [_formatter stringForObjectValue:@(value)];
    } else {
        self.toolTip = @(value).stringValue;
    }
}

- (void)mouseDown:(NSEvent *)event {
    _hitTestResult = [_selectionCell hitTestForEvent:event
                                              inRect:_cellFrame
                                              ofView:self];
    _mouseX = event.locationInWindow.x;

    if ((_hitTestResult == SLHCellHitNone ||
          _hitTestResult == SLHCellHitContentArea)
#if ENABLE_TRIMVIEW_DOUBLE_CLICK
         && event.clickCount < 2
#endif
    ) {
       [super mouseDown:event];
        return;
    } else if (_hitTestResult & SLHCellHitRightKnob || _hitTestResult & SLHCellHitLeftKnob) {
        [_delegate trimViewMouseDown:self];
        if (_hitTestResult & SLHCellHitLeftKnob) {
            [_delegate trimViewMouseDownStartPosition:self];
        } else {
            [_delegate trimViewMouseDownEndPosition:self];
        }
    }
    
    NSApplication *app = [NSApplication sharedApplication];
    NSEventMask eventMask = NSEventMaskLeftMouseUp | NSEventMaskLeftMouseDragged;
    
    while (1) {
        event = [app nextEventMatchingMask:eventMask
                                 untilDate:[NSDate distantFuture]
                                    inMode:NSEventTrackingRunLoopMode
                                   dequeue:YES];

        switch ([event type]) {
                
            case NSEventTypeLeftMouseDragged:
                [self mouseDragged:event];
                break;
            case NSEventTypeLeftMouseUp:
                [self mouseUp:event];
                _hitTestResult = SLHCellHitNone;
                return;
            default:
                break;
        }
        
    }
}

- (void)mouseUp:(NSEvent *)event {
    
    if (_hitTestResult & SLHCellHitRightKnob || _hitTestResult & SLHCellHitLeftKnob) {
        [_delegate trimViewMouseUp:self];
    }
    
#if ENABLE_TRIMVIEW_DOUBLE_CLICK
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
#endif
    
}

- (void)mouseDragged:(NSEvent *)event {
   // puts(__PRETTY_FUNCTION__);
    if (_hitTestResult & SLHCellHitLeftKnob ) {
        CGFloat newMouseX = event.locationInWindow.x;
        CGFloat deltaX = ((newMouseX - _mouseX) / (NSWidth(_maxSelectionFrame)) * _maxValue);
        double candidate = _startValue + deltaX;

        if (candidate <= _minValue) {
            _startValue = _minValue;
            self.needsDisplay = YES;
            return;
        }
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

        if (candidate >= _maxValue) {
            _endValue = _maxValue;
            self.needsDisplay = YES;
            return;
        }
        self.endValue = candidate;
        [self updateValue:@(_endValue) forBinding:@"endValue"];
        _mouseX = newMouseX;
        [_delegate trimViewMouseDraggedEndPosition:self];
        return;
    }
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

- (BOOL)wantsUpdateLayer {
#ifdef DEBUG_TRIMVIEW_DRAWING
    return NO;
#else
    return YES;
#endif
}

- (void)updateLayer {
    CGFloat startMark = (_startValue) / _maxValue * NSWidth(_maxSelectionFrame);
    CGFloat endMark = _endValue / _maxValue * NSWidth(_maxSelectionFrame);
    _cellFrame.origin.x = round(startMark);
    _cellFrame.size.width = round(endMark) - NSMinX(_cellFrame) + SLHMinWidth ;
    
    [_selectionCell drawWithFrame:_cellFrame inView:self];

}

- (void)drawRect:(NSRect)dirtyRect {
    [self updateLayer];

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
    [self reset];
    [super prepareForReuse];
}

@end

