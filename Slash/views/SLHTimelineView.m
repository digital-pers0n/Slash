//
//  SLHTimelineView.m
//  Slash
//
//  Created by Terminator on 2020/04/03.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLHTimelineView.h"
#import "SLHTimeFormatter.h"
@import QuartzCore.CAShapeLayer;
@import QuartzCore.CATextLayer;
@import QuartzCore.CATransaction;

static const CGFloat kSLHTimelineRulerHeight = 14.0;
static const CGFloat kSLHTimecodeFontSize = 9.0;
static const CGFloat kSLHTimecodeLayerWidth = 85.0;
static const NSUInteger kSLHTimelineNumOfSecondaryMarks = 10;
static const NSUInteger kSLHTimelineMinPrimaryMarksDistance = 90;
static const NSUInteger kSLHTimelineMaxPrimaryMarksDistance = 180;

@interface SLHTimelineRulerView : NSView {
    __weak SLHTimelineView *_timelineView;
    CAShapeLayer * _marksLayer;
    CAShapeLayer * _secondaryMarksLayer;
    NSMutableArray <CATextLayer *> *_timecodeLayers;
    CATextLayer * __unsafe_unretained *_timecodeLayersPtr;
    NSFont *_timecodeFont;
    NSColor * _timecodeFontColor;
    CGFloat _contentsScale;
    CGFloat _margin;
    CGFloat _currentWidth;
    NSUInteger _numberOfMarks;
    NSColor *_primaryMarkColor;
    NSColor *_backgroundColor;
    NSColor *_secondaryMarkColor;
}

@end

@implementation SLHTimelineRulerView

- (instancetype)initWithFrame:(NSRect)frame
                 timelineView:(SLHTimelineView *)tv
{
    self = [super initWithFrame:frame];
    if (self) {
        _timecodeLayers = [NSMutableArray array];
        _numberOfMarks = 2;
        _timelineView = tv;
        _primaryMarkColor = [NSColor secondaryLabelColor];
        _backgroundColor = [NSColor controlBackgroundColor];
        _secondaryMarkColor = [NSColor quaternaryLabelColor];

        _margin = tv.indicatorMargin;
        _marksLayer = [CAShapeLayer new];
        self.layer = _marksLayer;
        self.wantsLayer = YES;
        
        _secondaryMarksLayer = [CAShapeLayer new];
        _secondaryMarksLayer.anchorPoint = CGPointZero;
        _secondaryMarksLayer.position = CGPointZero;

        [_marksLayer addSublayer:_secondaryMarksLayer];
        [self updateColors];
        
        _timecodeFont = [NSFont fontWithName:@"Osaka" size:10];
        _timecodeFontColor = [NSColor secondaryLabelColor];
        
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self
               selector:@selector(timelineDidChangeFrame:)
                   name:NSViewFrameDidChangeNotification
                 object:tv];
        
        [tv addObserver:self
             forKeyPath:@"maxValue"
                options:NSKeyValueObservingOptionNew
                context:&SLHTimelineMaxValueKVOContext];
        [self updateTimecodeLayers];
    }
    return self;
}

- (void)updateColors {
    _marksLayer.fillColor = [_primaryMarkColor CGColor];
    _marksLayer.backgroundColor = [[_backgroundColor colorWithAlphaComponent:0.5] CGColor];
    _secondaryMarksLayer.fillColor = [_secondaryMarkColor CGColor];
}

#if MAC_OS_X_VERSION_10_14

- (void)viewDidChangeEffectiveAppearance {
    [super viewDidChangeEffectiveAppearance];
    [self updateColors];
    [self drawMarks];
}

#else

- (void)_viewDidChangeAppearance:(id)arg1 {
    [self updateColors];
    [self drawMarks];
}

#endif

- (void)viewDidChangeBackingProperties {
    [super viewDidChangeBackingProperties];
    _contentsScale = self.window.backingScaleFactor;
    for (CALayer * layer in _secondaryMarksLayer.sublayers) {
        layer.contentsScale = _contentsScale;
    }
}

- (void)dealloc
{
    if (_timecodeLayersPtr) {
        free(_timecodeLayersPtr);
    }
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
    [_timelineView removeObserver:self
                       forKeyPath:@"maxValue"
                          context:&SLHTimelineMaxValueKVOContext];
}

- (BOOL)isFlipped {
    return YES;
}

- (void)viewDidUnhide {
    [super viewDidUnhide];
    [self drawMarks];
}

#pragma mark - KVO

static char SLHTimelineMaxValueKVOContext;

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == &SLHTimelineMaxValueKVOContext) {
        [self drawMarks];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Marks

static void calcIntervalAndNumOfMarks(CGFloat w,
                                      NSUInteger * outInterval,
                                      NSUInteger * outMarks)
{
    int numOfMarks = 2;
    
    while (1) {
        for (NSUInteger i = kSLHTimelineMinPrimaryMarksDistance;
             i < kSLHTimelineMaxPrimaryMarksDistance; ++i)
        {
            CGFloat guess = i * numOfMarks;
            if (guess >= w) {
                *outInterval = i;
                *outMarks = numOfMarks;
                return;
            }
        }
        numOfMarks *= 2;
    }
}

static CATextLayer * createTimecodeLayer(NSFont * timecodeFont,
                                         CGColorRef timecodeFontColor,
                                         CGFloat contentsScale)
{
    CATextLayer *timecodeLayer = [CATextLayer new];
    timecodeLayer.anchorPoint = CGPointZero;
    timecodeLayer.font = (__bridge CFTypeRef)(timecodeFont);
    timecodeLayer.foregroundColor = timecodeFontColor;
    
    timecodeLayer.fontSize = kSLHTimecodeFontSize;
    timecodeLayer.contentsScale = contentsScale;
    
    return timecodeLayer;
}

- (void)updateTimecodeLayers {
    NSUInteger count = _timecodeLayers.count;
    if (count < _numberOfMarks) {
        count = _numberOfMarks - count;
        CGColorRef const timecodeFontColor = _timecodeFontColor.CGColor;
        NSFont * const timecodeFont = _timecodeFont;
        const CGFloat contentsScale = _contentsScale;
        while (count) {
            CATextLayer * tl = createTimecodeLayer(timecodeFont,
                                                   timecodeFontColor,
                                                   contentsScale);
            [_timecodeLayers addObject:tl];
            --count;
        }
    }
    if (_timecodeLayersPtr) {
        free(_timecodeLayersPtr);
    }
    NSRange range = NSMakeRange(0, _numberOfMarks);
    _timecodeLayersPtr = (typeof(_timecodeLayersPtr))malloc(sizeof(CATextLayer *) * range.length);
    
    [_timecodeLayers getObjects:_timecodeLayersPtr range:range];
    
    [CATransaction begin];
    [CATransaction setValue:@YES forKey:kCATransactionDisableActions];
    _secondaryMarksLayer.sublayers = [_timecodeLayers subarrayWithRange:range];
    [CATransaction commit];
}

- (void)drawMarks {
    if (!_currentWidth) { return; }
    [self setFrameSize:NSMakeSize(_currentWidth, kSLHTimelineRulerHeight)];
    
    const double maxValue = _timelineView.maxValue;
    const CGFloat margin = _timelineView.indicatorMargin;
    const CGFloat width = _currentWidth - (margin * 2);
    NSUInteger numOfMarks = _numberOfMarks;
    
    NSUInteger interval = (width / numOfMarks);
    if (interval > kSLHTimelineMaxPrimaryMarksDistance ||
        interval < kSLHTimelineMinPrimaryMarksDistance)
    {
        calcIntervalAndNumOfMarks(width, &interval, &numOfMarks);
        _numberOfMarks = numOfMarks;
        [self updateTimecodeLayers];
    }
    
    CGMutablePathRef primaryPath = CGPathCreateMutable();
    CGMutablePathRef secondaryPath = CGPathCreateMutable();
    
    CGRect primaryMark = CGRectMake(0, 0, 1,
                                    kSLHTimelineRulerHeight /* 0.75*/);
    CGRect secondaryMark = primaryMark;
    secondaryMark.size.height = kSLHTimelineRulerHeight - 2; /* 0.75*/;
    
    const CGFloat step = interval;
    const CGFloat secondaryStep = (step / kSLHTimelineNumOfSecondaryMarks);
    const double timecode = (step / width * maxValue);
    CGRect timecodeFrame = CGRectMake(0, 1,
                                      kSLHTimecodeLayerWidth,
                                      kSLHTimelineRulerHeight);
    
    [CATransaction begin];
    [CATransaction setValue:@YES forKey:kCATransactionDisableActions];
    for (NSUInteger i = 0; i < numOfMarks; ++i) {
        primaryMark.origin.x = step * i + margin;
        CGPathAddRect(primaryPath, nil, primaryMark);
        for (NSUInteger j = 1; j < kSLHTimelineNumOfSecondaryMarks; ++j) {
            secondaryMark.origin.x = secondaryStep * j + NSMinX(primaryMark);
            CGPathAddRect(secondaryPath, nil, secondaryMark);
        }
        
        CATextLayer *timecodeLayer = _timecodeLayersPtr[i];
        timecodeFrame.origin.x = NSMinX(primaryMark) + 5;

        timecodeLayer.frame = timecodeFrame;
        timecodeLayer.string = SLHTimeFormatterStringForDoubleValue((timecode * i));
        
    }
    [CATransaction commit];
    
    _marksLayer.path = primaryPath;
    _secondaryMarksLayer.path = secondaryPath;
    
    CGPathRelease(primaryPath);
    CGPathRelease(secondaryPath);
}

- (void)timelineDidChangeFrame:(NSNotification *)n {
    CGFloat width = NSWidth(_timelineView.frame);
    if (width == _currentWidth) { return; }
    _currentWidth = width;
    [self drawMarks];
}

@end

@interface SLHTimelineView () {
    CAShapeLayer *_indicatorLayer;
    __weak NSView *_overlay;
    CGFloat _indicatorMargin;
    NSRect _indicatorFrame;
    NSRect _currentFrame;
    NSRect _workingArea;
    BOOL _mouseIn;
    NSTrackingArea *_trackingArea;
}

@end


@implementation SLHTimelineView

- (void)setUp {
    if (_maxValue == 0) {
        self.maxValue = 1;
    }
    _trackingArea = [NSTrackingArea new];
    
    _currentFrame = self.frame;
    _indicatorFrame = NSMakeRect(_indicatorMargin, 0, 1, NSHeight(_currentFrame));
    _workingArea = NSInsetRect(_currentFrame, _indicatorMargin, 0);
    _indicatorLayer = [self indicatorLayerWithSize:_currentFrame.size];
    
    self.wantsLayer = YES;
}

#pragma mark - Overrides

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUp];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setUp];
    }
    return self;
}

- (CAShapeLayer *)indicatorLayerWithSize:(CGSize)size {
    CAShapeLayer * layer = [CAShapeLayer new];
    layer.fillColor = [[NSColor systemRedColor] CGColor];
    layer.bounds = CGRectMake(0, 0, size.width, size.height);
    layer.position = CGPointZero;
    layer.anchorPoint = CGPointZero;
    layer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    return layer;
}

- (void)viewDidMoveToSuperview {
    [super viewDidMoveToSuperview];
    NSScrollView * sv = self.enclosingScrollView;
    if (sv) {
        NSRect frame = NSMakeRect(0, 0, NSWidth(_currentFrame),
                                  kSLHTimelineRulerHeight);
        SLHTimelineRulerView * ruler;
        ruler = [[SLHTimelineRulerView alloc] initWithFrame:frame
                                               timelineView:self];
        // key="autoresizingMask" flexibleMaxX="YES" flexibleMinY="YES"
        ruler.autoresizingMask = NSViewMaxXMargin | NSViewMinYMargin;

        [sv addFloatingSubview:ruler forAxis:NSEventGestureAxisVertical];

        NSPoint pt;
        pt = NSMakePoint(0, NSHeight(ruler.superview.frame) - kSLHTimelineRulerHeight);
        [ruler setFrameOrigin:pt];
        ruler.superview.autoresizesSubviews = YES;
        
        frame.size = NSMakeSize(NSWidth(_currentFrame), NSHeight(sv.frame));
        NSView *overlay = [[NSView alloc] initWithFrame:frame];
        [sv addFloatingSubview:overlay forAxis:NSEventGestureAxisVertical];
        overlay.layer = _indicatorLayer;
        overlay.wantsLayer = YES;
        _overlay = overlay;
    }
}

- (void)setFrame:(NSRect)frame {
    _currentFrame = frame;
    _workingArea = NSInsetRect(_currentFrame, _indicatorMargin, 0);
    
    NSRect dvFrame = _documentView.frame;
    if (NSHeight(frame) < NSHeight(dvFrame)) {
        frame.size.height = NSHeight(dvFrame);
    } else {
        NSScrollView *sv = self.enclosingScrollView;
        if (sv) {
            
            NSRect svFrame = sv.frame;
            
            CGFloat newY = round((NSHeight(svFrame) - NSHeight(dvFrame)) * (CGFloat)0.5);
            if (newY != NSMinY(dvFrame)) {
                dvFrame.origin.y = newY;
                _documentView.frame = dvFrame;
            }
            
            frame.size.height = NSHeight(svFrame);
        }
    }
    [_overlay setFrameSize:frame.size];
    [super setFrame:frame];
    [self updateIndicatorPosition];
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    [self removeTrackingArea:_trackingArea];
    NSTrackingAreaOptions trackingOptions = NSTrackingActiveInKeyWindow |
                                            NSTrackingMouseEnteredAndExited;
    
    _trackingArea = [[NSTrackingArea alloc] initWithRect:NSInsetRect(_indicatorFrame, -4, 0)
                                                 options:trackingOptions
                                                   owner:self
                                                userInfo:nil];
    [self addTrackingArea:_trackingArea];
}

- (BOOL)isFlipped {
    return NO;
}

- (BOOL)canBecomeKeyView {
    return YES;
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)mouseEntered:(NSEvent *)event {
    _mouseIn = YES;
    [NSCursor pop];
    [[NSCursor resizeLeftRightCursor] push];
}

- (void)mouseExited:(NSEvent *)event {
    _mouseIn = NO;
    [NSCursor pop];
}

- (void)mouseDown:(NSEvent *)event {
    if (_mouseIn) {
        NSApplication *app = [NSApplication sharedApplication];
        NSEventMask eventMask = NSEventMaskLeftMouseUp | NSEventMaskLeftMouseDragged;
        [_delegate timelineViewMouseDown:self];
        
        while (1) {
            event = [app nextEventMatchingMask:eventMask
                                     untilDate:[NSDate distantFuture]
                                        inMode:NSEventTrackingRunLoopMode
                                       dequeue:YES];
            
            switch ([event type]) {
                    
                case NSEventTypeLeftMouseDragged:
                    [self updateIndicatorPositionWithEvent:event];
                    break;
                case NSEventTypeLeftMouseUp:
                    [self mouseUp:event];
                    [self updateTrackingAreas];
                    [_delegate timelineViewMouseUp:self];
                    _mouseIn = NO;
                    return;
                default:
                    break;
            }
        }
    } else if (event.clickCount > 1) {
        [_delegate timelineViewMouseDown:self];
        [self updateIndicatorPositionWithEvent:event];
        [self updateTrackingAreas];
        [_delegate timelineViewMouseUp:self];
    }
    [self.window makeFirstResponder:self];
    [super mouseDown:event];
}

#pragma mark - Methods

static double mousePointToDoubleValue(NSPoint point,
                                      NSRect trackRect,
                                      NSRect indicatorRect,
                                      double maxValue, double minValue) {
    CGFloat position;
    const CGFloat indicatorHalfWidth = NSWidth(indicatorRect) * (CGFloat)0.5;
    
    if (point.x < NSMinX(trackRect) + indicatorHalfWidth) {
        position = NSMinX(trackRect) + indicatorHalfWidth;
    }
    else if (point.x > NSMaxX(trackRect) - indicatorHalfWidth) {
        position = NSMaxX(trackRect) - indicatorHalfWidth;
    }
    else {
        position = point.x;
    }
    
    const CGFloat result = (position - (NSMinX(trackRect) + indicatorHalfWidth))
                          / (NSWidth(trackRect) - NSWidth(indicatorRect));
    
    return result * (maxValue - minValue) + minValue;
}

- (void)updateIndicatorPosition {
    NSSize size = _indicatorFrame.size;
    NSRect trackRect = _workingArea;
    
    CGFloat scale = (_doubleValue - _minValue) / (_maxValue - _minValue);
    
    NSPoint origin = trackRect.origin;
    origin.x += round((NSWidth(trackRect) - size.width) * scale);
    
    _indicatorFrame.origin.x = origin.x;
    _indicatorFrame.size.height = NSHeight(trackRect);
    CGPathRef path = CGPathCreateWithRect(_indicatorFrame, nil);
    _indicatorLayer.path = path;
    CFRelease(path);
}


- (void)updateIndicatorPositionWithEvent:(NSEvent *)event {

    NSPoint local_point = [self convertPoint:event.locationInWindow
                                    fromView:nil];
    self.doubleValue = mousePointToDoubleValue(local_point,
                                               _workingArea, _indicatorFrame,
                                               _maxValue, _minValue);
    [self autoscroll:event];
    [self updateIndicatorPosition];

}

@end
