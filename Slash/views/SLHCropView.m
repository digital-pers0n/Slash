//
//  SLHCropView.m
//  Slash
//
//  Created by Terminator on 2019/11/22.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHCropView.h"

//#define DEBUG_CROPVIEW_DRAWING

typedef NS_ENUM(NSUInteger, SLHTrackingArea) {
    SLHTrackingAreaTop,
    SLHTrackingAreaBottom,
    SLHTrackingAreaLeft,
    SLHTrackingAreaRight,
    SLHTrackingAreaTopLeft,
    SLHTrackingAreaTopRight,
    SLHTrackingAreaBottomLeft,
    SLHTrackingAreaBottomRight,
    SLHTrackingAreaNone
};

#define SLHTrackingAreasCount  SLHTrackingAreaNone

static NSString * const SLHTrackingAreaKey = @"trackingAreaKey";

@interface SLHCropView () {
    BOOL _isInRect;
    BOOL _isDragging;
    
    NSTrackingArea *_trackingAreas[SLHTrackingAreasCount];
    SLHTrackingArea _activeArea;
    
    NSRect _cropRect;       ///< selection in view's coordinates
    NSRect _selectionRect;  ///< selection in user content's coordinates
    NSSize _size;           ///< user content's size
    NSRect _scaledRect;     ///< user content's size scaled to view's coordinates
    NSRect _currentFrame;   ///< current frame of view
}


@end

@implementation SLHCropView

#pragma mark - *** Initialization ***

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
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

- (void)setUp {
    _currentFrame = self.frame;
    _activeArea = SLHTrackingAreaNone;
    _cropRect = _currentFrame;
    _size = _cropRect.size;
    _tintColor = [NSColor.purpleColor colorWithAlphaComponent:0.3];
    _lineColor = NSColor.whiteColor;
}

#pragma mark - *** Properties ***

- (void)setSize:(NSSize)size {
    _size = size;
    _scaledRect = fitSizeToRect(size, _currentFrame);
}



- (void)setSelectionRect:(NSRect)selectionRect {
    _selectionRect = selectionRect;
    _cropRect = convertRectToView(selectionRect, _size, _scaledRect);
    self.needsDisplay = YES;
}

#pragma mark - *** Overrides ***

- (void)setFrame:(NSRect)frame {
    _currentFrame = frame;
    _scaledRect = fitSizeToRect(_size, frame);
    _cropRect = convertRectToView(_selectionRect, _size, _scaledRect);
    
    [super setFrame:frame];
}
- (void)drawRect:(NSRect)dirtyRect {
    
    /* Use CGPathRef here, because maybe it would be better to migrate to CAShapeLayer in the future, and CGPathRef with CAShapeLayer work well together */
    CGContextRef context = NSGraphicsContext.currentContext.CGContext;
    
    CGMutablePathRef ref = CGPathCreateMutable();
    CGPathAddRect(ref, nil, self.bounds);
    CGPathAddRect(ref, nil, _cropRect);
    
    CGContextAddPath(context, ref);
    CGContextSetFillColorWithColor(context, _tintColor.CGColor);
    CGContextDrawPath(context, kCGPathEOFill);
    
    CGPathRef dash = CGPathCreateWithRect(NSInsetRect(_cropRect, -2, -2), nil);
    
    const CGFloat lengts[] = { 5, 2 };
    CGContextSetLineDash(context, 0, lengts, 2);
    CGContextSetLineWidth(context, 2);
    CGContextAddPath(context, dash);
    CGContextSetStrokeColorWithColor(context, _lineColor.CGColor);
    
    CGContextDrawPath(context, kCGPathStroke);
    
    CGPathRelease(dash);
    CGPathRelease(ref);
    
#ifdef DEBUG_CROPVIEW_DRAWING
    [[NSColor redColor] set];
    NSFrameRect(_scaledRect);
#endif
    
}


- (BOOL)isFlipped {
    return YES;
}

#pragma mark Mouse Events

- (void)mouseDown:(NSEvent *)event {
    NSPoint event_location = event.locationInWindow;
    NSPoint local_point = [self convertPoint:event_location fromView:nil];
    
    if ([self mouse:local_point inRect:_cropRect]) {
        _isInRect = YES;
        [NSCursor pop];
        [[NSCursor closedHandCursor] push];
    } else if (_activeArea == SLHTrackingAreaNone) {
        _isInRect = NO;
        /* Make new selection */
        _cropRect.origin = NSMakePoint(round(local_point.x), round(local_point.y));
        _cropRect.size = NSMakeSize(1, 1);
    }
    _isDragging = YES;
}

static inline void resizeTop(NSRect *rect, CGFloat delta) {
    rect->origin.y += delta;
    rect->size.height -= delta;
}

static inline void resizeBottom(NSRect *rect, CGFloat delta) {
    rect->size.height += delta;
}

static inline void resizeLeft(NSRect *rect, CGFloat delta) {
    rect->origin.x += delta;
    rect->size.width -= delta;
}

static inline void resizeRight(NSRect *rect, CGFloat delta) {
    rect->size.width += delta;
}

- (void)mouseDragged:(NSEvent *)event {
    
    CGFloat deltaY = event.deltaY;
    CGFloat deltaX = event.deltaX;
    
    if (_activeArea != SLHTrackingAreaNone) {
        
        switch (_activeArea) {
                
            case SLHTrackingAreaTop:
            {
                resizeTop(&_cropRect, deltaY);
            }
                break;
                
            case SLHTrackingAreaBottom:
            {
                resizeBottom(&_cropRect, deltaY);
            }
                break;
                
            case SLHTrackingAreaLeft:
            {
                resizeLeft(&_cropRect, deltaX);
            }
                break;
                
            case SLHTrackingAreaRight:
            {
                resizeRight(&_cropRect, deltaX);
            }
                break;
                
            case SLHTrackingAreaTopLeft:
            {
                resizeTop(&_cropRect, deltaY);
                resizeLeft(&_cropRect, deltaX);
            }
                break;
                
            case SLHTrackingAreaTopRight:
            {
                resizeTop(&_cropRect, deltaY);
                resizeRight(&_cropRect, deltaX);
            }
                break;
                
            case SLHTrackingAreaBottomLeft:
            {
                resizeBottom(&_cropRect, deltaY);
                resizeLeft(&_cropRect, deltaX);
            }
                break;
                
            case SLHTrackingAreaBottomRight:
            {
                resizeBottom(&_cropRect, deltaY);
                resizeRight(&_cropRect, deltaX);
            }
                break;
                
            default:
                break;
        }
        
        goto done;
    }
    
    if (_isInRect) {
        
        _cropRect.origin.x += deltaX;
        _cropRect.origin.y += deltaY;
        
        goto done;
    }
    
    _cropRect.size.width += deltaX;
    _cropRect.size.height += deltaY;
    
done:
    _selectionRect = convertRectFromView(_cropRect, _scaledRect, _size);
    self.needsDisplay = YES;
#ifdef DEBUG
    printf("selection:\n"
           "x = %g\n"
           "y = %g\n"
           "w = %g\n"
           "h = %g\n",
           NSMinX(_selectionRect), NSMinY(_selectionRect), NSWidth(_selectionRect), NSHeight(_selectionRect));
#endif
}

- (void)mouseUp:(NSEvent *)event {
    
    if (NSHeight(_cropRect) < 0) {
        _cropRect.size.height = fabs(NSHeight(_cropRect));
        _cropRect.origin.y -= NSHeight(_cropRect);
    }
    
    if (NSWidth(_cropRect) < 0) {
        _cropRect.size.width = fabs(NSWidth(_cropRect));
        _cropRect.origin.x -= NSWidth(_cropRect);
    }
    _selectionRect = convertRectFromView(_cropRect, _scaledRect, _size);
    [self updateTrackingAreas];
    _isDragging = NO;
    _activeArea = SLHTrackingAreaNone;
    self.needsDisplay = YES;
    [NSCursor pop];
}

#pragma mark  Mouse Tracking

- (void)mouseEntered:(NSEvent *)event {
    NSDictionary *user = event.userData;
    _activeArea = [user[SLHTrackingAreaKey] unsignedIntegerValue];

    [NSCursor pop];
    [[NSCursor crosshairCursor] push];
}

- (void)mouseExited:(NSEvent *)event {
    if (!_isDragging) {
        _activeArea = SLHTrackingAreaNone;
        [NSCursor pop];
    }
}

#define areaOffset 2
#define areaSize 4
#define cornerSize 12

- (void)updateTrackingAreas {
    
    [super updateTrackingAreas];
    
    for (int i = 0; i < SLHTrackingAreasCount; i++) {
        [self removeTrackingArea:_trackingAreas[i]];
    }
    CGFloat x = NSMinX(_cropRect);
    CGFloat y = NSMinY(_cropRect);
    CGFloat width = NSWidth(_cropRect);
    CGFloat height = NSHeight(_cropRect);
    
    NSTrackingAreaOptions trackingOptions = NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow;
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    
    userInfo[SLHTrackingAreaKey] = @(SLHTrackingAreaTop);
    NSRect rect = NSMakeRect(x + 10, y - areaOffset, width - 20, areaSize);
    _trackingAreas[SLHTrackingAreaTop] = [[NSTrackingArea alloc] initWithRect:rect
                                                                      options:trackingOptions
                                                                        owner:self
                                                                     userInfo:userInfo.copy];
    
    userInfo[SLHTrackingAreaKey] = @(SLHTrackingAreaBottom);
    rect.origin.y = y + height - areaOffset;
    _trackingAreas[SLHTrackingAreaBottom] = [[NSTrackingArea alloc] initWithRect:rect
                                                                         options:trackingOptions
                                                                           owner:self
                                                                        userInfo:userInfo.copy];
    userInfo[SLHTrackingAreaKey] = @(SLHTrackingAreaLeft);
    rect = NSMakeRect(x - areaOffset, y + 10, areaSize, height - 20);
    _trackingAreas[SLHTrackingAreaLeft] = [[NSTrackingArea alloc] initWithRect:rect
                                                                       options:trackingOptions
                                                                         owner:self
                                                                      userInfo:userInfo.copy];
    
    userInfo[SLHTrackingAreaKey] = @(SLHTrackingAreaRight);
    rect.origin.x = x + width - areaOffset;
    _trackingAreas[SLHTrackingAreaRight] = [[NSTrackingArea alloc] initWithRect:rect
                                                                        options:trackingOptions
                                                                          owner:self
                                                                       userInfo:userInfo.copy];
    
    userInfo[SLHTrackingAreaKey] = @(SLHTrackingAreaTopLeft);
    rect = NSMakeRect(x - areaOffset, y - areaOffset, cornerSize, cornerSize);
    _trackingAreas[SLHTrackingAreaTopLeft] = [[NSTrackingArea alloc] initWithRect:rect
                                                                          options:trackingOptions
                                                                            owner:self
                                                                         userInfo:userInfo.copy];
    
    userInfo[SLHTrackingAreaKey] = @(SLHTrackingAreaTopRight);
    rect.origin.x = x + width - cornerSize + areaOffset;
    _trackingAreas[SLHTrackingAreaTopRight] = [[NSTrackingArea alloc] initWithRect:rect
                                                                           options:trackingOptions
                                                                             owner:self
                                                                          userInfo:userInfo.copy];
    
    userInfo[SLHTrackingAreaKey] = @(SLHTrackingAreaBottomRight);
    rect.origin.y = y + height - cornerSize + areaOffset;
    _trackingAreas[SLHTrackingAreaBottomRight] = [[NSTrackingArea alloc] initWithRect:rect
                                                                              options:trackingOptions
                                                                                owner:self
                                                                             userInfo:userInfo.copy];
    userInfo[SLHTrackingAreaKey] = @(SLHTrackingAreaBottomLeft);
    rect.origin.x = x - areaOffset;
    _trackingAreas[SLHTrackingAreaBottomLeft] = [[NSTrackingArea alloc] initWithRect:rect
                                                                             options:trackingOptions
                                                                               owner:self
                                                                            userInfo:userInfo];
    
    
    for (int i = 0; i < SLHTrackingAreasCount; i++) {
        [self addTrackingArea:_trackingAreas[i]];
    }
}

#pragma mark - *** Functions ***

/**
 * Fit @c size into the @c rect
 * @param size size of the user's content
 * @param rect rectange into that @c size should be fitted
 * @return scaled version of @c size that is center aligned inside @c rect
 * @note the .width and .height of @c rect and @c size must not equal to zero
 */
static inline NSRect fitSizeToRect(const NSSize size, const NSRect rect) {
    NSRect result;
    /* Calculate width or height using a formula derived from the proportion of similar rectangles w1 * h2 = w2 * h1
     */
    if ((NSWidth(rect) / NSHeight(rect)) < (size.width / size.height)) { // fit to width
        result.size.width = NSWidth(rect);
        result.size.height = round((size.height * NSWidth(rect)) / size.width);
        result.origin.y = round((NSHeight(rect) - NSHeight(result)) * (CGFloat)0.5);
        result.origin.x = 0;
    } else { // fit to height
        result.size.height = NSHeight(rect);
        result.size.width = round((size.width * NSHeight(rect)) /  size.height);
        result.origin.x = round((NSWidth(rect) - NSWidth(result)) * (CGFloat)0.5);
        result.origin.y = 0;
    }
    
    return result;
}

/**
 * Convert @c sourceRect that lies inside @c sourceSize into @c destinationRect coordinates.
 * @note the .width and .height of @c sourceSize must not equal to zero.
 */
static inline NSRect
convertRectToView(NSRect sourceRect,
                  NSSize sourceSize,
                  NSRect destinationRect) {
    
    NSRect result;
    
    CGFloat scaleW =  destinationRect.size.width / sourceSize.width;
    CGFloat scaleH =  destinationRect.size.height / sourceSize.height;
    
    result.origin.x = round(NSMinX(sourceRect) * scaleW + NSMinX(destinationRect));
    result.origin.y = round(NSMinY(sourceRect) * scaleH + NSMinY(destinationRect));
    result.size.width = round(NSWidth(sourceRect) * scaleW);
    result.size.height = round(NSHeight(sourceRect) * scaleH);
    
    return result;
}

/**
 * Convert @c sourceRect into @c destinationSize coordinates.
 * @note the .width and .height of @c viewFrame must not equal to zero.
 * @param viewFrame rectange where @c sourceRect lies
 */
static inline NSRect
convertRectFromView(NSRect sourceRect,
                    NSRect viewFrame,
                    NSSize destinationSize) {
    NSRect result;
    
    CGFloat scaleW = destinationSize.width / NSWidth(viewFrame);
    CGFloat scaleH = destinationSize.height / NSHeight(viewFrame);
    
    result.origin.x = round((NSMinX(sourceRect) - NSMinX(viewFrame)) * scaleW);
    result.origin.y = round((NSMinY(sourceRect) - NSMinY(viewFrame)) * scaleH);
    result.size.width = round(NSWidth(sourceRect) * scaleW);
    result.size.height = round(NSHeight(sourceRect) * scaleH);
    
    return result;
}


@end
