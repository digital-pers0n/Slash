//
//  SLKDisclosureView.m
//  Slash
//
//  Created by Terminator on 2020/8/19.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLKDisclosureView.h"
#import "MPVKitDefines.h"

static const CGFloat SLKHeaderViewHeight = 20.0;
static const CGFloat SLKHeaderViewFontSize = 10.0;
static const CGFloat SLKHeaderViewMargin = 7.0;

#pragma mark - **** SLHDisclosureHeaderView ****

@interface SLKDisclosureHeaderView : NSView {
    @package
    NSButtonCell *_buttonCell;
    NSRect _buttonFrame;
    NSTrackingArea *_trackingArea;
    BOOL _mouseIn;
    NSTextFieldCell *_titleCell;
    BOOL _closed;
}

- (void)updateButtonFrame OBJC_DIRECT;
- (BOOL)isMouseIn OBJC_DIRECT;

/** Bound to _buttonCell.value */
@property (nonatomic) BOOL closed;

@end

@implementation SLKDisclosureHeaderView

#pragma mark - Overrides

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _titleCell = [[NSTextFieldCell alloc] initTextCell:@"Empty"];
        _titleCell.bordered = NO;
        _titleCell.font = [NSFont boldSystemFontOfSize:SLKHeaderViewFontSize];
        _buttonCell = [[NSButtonCell alloc] init];
        [_buttonCell setButtonType:NSButtonTypeToggle];
        _buttonCell.title = @"Hide";
        _buttonCell.alternateTitle = @"Show";
        _buttonCell.bordered = NO;
        _buttonCell.font = [NSFont boldSystemFontOfSize:SLKHeaderViewFontSize];
        [_buttonCell bind:NSValueBinding
                 toObject:self withKeyPath:@"closed" options:nil];
        [self updateButtonFrame];
        _trackingArea = [[NSTrackingArea alloc] init];
    }
    return self;
}

- (BOOL)isFlipped {
    return NO;
}

- (void)setFrame:(NSRect)frame {
    _buttonFrame.origin.x = NSWidth(frame) - NSWidth(_buttonFrame);
    [super setFrame:frame];
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    [self removeTrackingArea:_trackingArea];
    NSTrackingAreaOptions opts = NSTrackingMouseEnteredAndExited |
                          NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect;
    id area = [[NSTrackingArea alloc] initWithRect:NSZeroRect
                                           options:opts owner:self userInfo:nil];
    [self addTrackingArea:area];
    _trackingArea = area;
    
    if (_mouseIn) {
        /* Fixes problems with mouseExited: events in scroll views */
        BOOL flag = [self isMouseIn];
        if (!flag) {
            _mouseIn = flag;
            self.needsDisplay = YES;
        }
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    NSRect rect = NSInsetRect(self.bounds, SLKHeaderViewMargin, 3);
    [_titleCell drawInteriorWithFrame:rect inView:self];
    
    if (_closed || _mouseIn) {
        rect = NSInsetRect(_buttonFrame, SLKHeaderViewMargin, 3);
        [_buttonCell drawInteriorWithFrame:rect inView:self];
    }
}

#pragma mark Mouse Events

- (void)mouseEntered:(NSEvent *)event {
    _mouseIn = YES;
    self.needsDisplay = YES;
}

- (void)mouseExited:(NSEvent *)event {
    _mouseIn = NO;
    self.needsDisplay = YES;
}

- (void)mouseUp:(NSEvent *)event {
    NSPoint point = [self convertPoint:event.locationInWindow fromView:nil];
    if (NSMouseInRect(point, _buttonFrame, /* flipped */ NO)) {
        self.closed = (_closed) ? NO : YES;
        [self updateButtonFrame];
        self.needsDisplay = YES;
    }
}

#pragma mark - Methods

- (void)updateButtonFrame {
    CGFloat width = NSWidth(self.bounds);
    CGFloat cellWidth = _buttonCell.cellSize.width;
    _buttonFrame = NSMakeRect(width - (cellWidth + SLKHeaderViewMargin * 2), 0,
                   cellWidth + SLKHeaderViewMargin * 2, SLKHeaderViewHeight);
}

- (BOOL)isMouseIn {
    NSWindow *window = self.window;
    NSPoint mouseLocation = window.mouseLocationOutsideOfEventStream;
    mouseLocation = [window.contentView convertPoint:mouseLocation toView:self];
    return NSMouseInRect(mouseLocation, self.bounds, /* flipped */ NO);
}

@end // SLKDisclosureHeaderView

#pragma mark - **** SLHDisclosureView ****

@interface SLKDisclosureView () {
    NSSize _savedSize;
    __unsafe_unretained SLKDisclosureHeaderView *_headerView;
}
@end

OBJC_DIRECT_MEMBERS
@implementation SLKDisclosureView

static NSColor *_separatorColor;

#pragma mark - Overrides

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)init {
    return [self initWithFrame:NSMakeRect(0, 0, 50, SLKHeaderViewHeight)];
}

- (void)setFrame:(NSRect)frame {
    _savedSize.width = NSWidth(frame);
    _currentFrame = frame;
    [super setFrame:frame];
}

static char KVO_SLKHeaderViewClosed;

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
    if (context == &KVO_SLKHeaderViewClosed) {
        NSSize savedSize = _currentFrame.size;
        [self willChangeValueForKey:@"currentFrame"];
        [self resizeTo:_savedSize];
        [self didChangeValueForKey:@"currentFrame"];
        _savedSize = savedSize;
    } else {
        [super observeValueForKeyPath:keyPath
                             ofObject:object change:change context:context];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    NSRect frame = _currentFrame;
    frame.size.height = 1;
    frame.origin = (NSPoint){ 0, 0 };
    [_separatorColor set];
    [NSBezierPath fillRect:frame];
}

- (BOOL)isFlipped {
    return NO;
}

- (void)dealloc {
    [_headerView removeObserver:self
                     forKeyPath:@"closed" context:&KVO_SLKHeaderViewClosed];
}

#pragma mark - Methods

- (void)commonInit {
    NSRect frame = self.frame;
    _currentFrame = frame;
    NSRect headerFrame = NSMakeRect(0, NSHeight(frame) - SLKHeaderViewHeight,
                                    NSWidth(frame), SLKHeaderViewHeight);
    SLKDisclosureHeaderView *hv;
    hv = [[SLKDisclosureHeaderView alloc] initWithFrame:headerFrame];
    [hv addObserver:self
         forKeyPath:@"closed" options:0 context:&KVO_SLKHeaderViewClosed];
    hv.autoresizingMask = NSViewMinXMargin | NSViewMinYMargin | NSViewWidthSizable;
    [self addSubview:hv];
    _savedSize = headerFrame.size;
    _headerView = hv;
    if (!_separatorColor) {
        _separatorColor = NSColor.gridColor;
    }
}

- (void)setContentView:(NSView *)contentView {
    [_contentView removeFromSuperview];
    _contentView = contentView;
    if (contentView != nil) {
        NSRect newContentFrame = contentView.frame;
        NSSize newSize = _currentFrame.size;
        newContentFrame.size.width = newSize.width;
        newSize.height = NSHeight(newContentFrame) + SLKHeaderViewHeight;
        [self resizeTo:newSize];
        contentView.frame = newContentFrame;
        [self addSubview:contentView];
    }
}

- (void)resizeTo:(NSSize)newSize {
    NSRect newFrame = _currentFrame;
    CGFloat yOffset = newSize.height - NSHeight(newFrame);
    newFrame.origin.y -= yOffset;
    newFrame.size = newSize;
    self.frame = newFrame;
}

@end
