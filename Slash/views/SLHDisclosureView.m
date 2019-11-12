//
//  SLHDisclosureView.m
//  Slash
//
//  Created by Terminator on 2019/11/10.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHDisclosureView.h"

//#define DEBUG_DISCLOSUREVIEW_DRAWING

#define SLHHeaderHeight 20
#define SLHSideMargin   7

typedef void (*action_imp)(id, SEL, id);

#pragma mark -
#pragma mark **** SLHDisclosureHeaderView ****

@interface SLHDisclosureHeaderView : NSView {
    
    NSTextFieldCell *_buttonCell;
    NSRect _buttonFrame;
    NSTrackingArea *_trackingArea;
    BOOL _mouseIn;
    
    @package
    NSTextFieldCell *_titleCell;
    BOOL _closed;
}

@property (nonatomic, nullable, weak) id target;
@property (nonatomic, nullable) SEL action;
@property (nonatomic, nullable) action_imp actionIMP;

@end

@implementation SLHDisclosureHeaderView

#pragma mark - Initialization

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _titleCell = [[NSTextFieldCell alloc] initTextCell:@"Empty"];
        _titleCell.bordered = NO;
        _titleCell.font = [NSFont boldSystemFontOfSize:10];
        _buttonCell = [[NSTextFieldCell alloc] initTextCell:@"Hide"];
        _buttonCell.bordered = NO;
        _buttonCell.font = [NSFont boldSystemFontOfSize:10];
        _buttonCell.textColor = [NSColor disabledControlTextColor];
        [self updateButtonFrame];
        _trackingArea = [NSTrackingArea new];
    }
    return self;
}

#pragma mark - Methods

- (void)updateButtonFrame {
    _buttonFrame = NSMakeRect(NSWidth(self.bounds) - (_buttonCell.cellSize.width + SLHSideMargin * 2),
                              0,
                              _buttonCell.cellSize.width + SLHSideMargin * 2,
                              SLHHeaderHeight);
}

- (void)setTarget:(id)target {
    _actionIMP = (action_imp)get_method_address(target, _action);
    _target = target;
}

- (void)setAction:(SEL)action {
    _actionIMP = (action_imp)get_method_address(_target, action);
    _action = action;
}

- (BOOL)isMouseIn {
    NSWindow *window = self.window;
    NSPoint mouse_location = [window mouseLocationOutsideOfEventStream];
    NSPoint local_point = [window.contentView convertPoint:mouse_location toView:self];
    return [self mouse:local_point inRect:self.bounds];
}

static IMP get_method_address(id target, SEL selector) {
    if (target && selector && [target respondsToSelector:selector]) {
        return [target methodForSelector:selector];
    }
    return nil;
}

#pragma mark - Overrides

- (void)setFrame:(NSRect)frame {
    _buttonFrame.origin.x = NSWidth(frame) - NSWidth(_buttonFrame);
    [super setFrame:frame];
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    [self removeTrackingArea:_trackingArea];
    NSTrackingArea *area = [[NSTrackingArea alloc]
                            initWithRect:NSZeroRect
                            options: NSTrackingMouseEnteredAndExited  | NSTrackingActiveInKeyWindow |  NSTrackingInVisibleRect
                            owner:self
                            userInfo:nil];
    [self addTrackingArea:area];
    _trackingArea = area;
    
    if (_mouseIn) {
        /* We will not get mouseExited: events during scrolling inside NSScrollView,
         check if the mouse pointer is outside of the view's bounds. */
        BOOL flag = [self isMouseIn];
        if (!flag) {
            _mouseIn = flag;
            self.needsDisplay = YES;
        }
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    
    [_titleCell drawWithFrame:NSInsetRect(self.bounds,  SLHSideMargin, 3) inView:self];
    
    if (_closed || _mouseIn) {
        [_buttonCell drawWithFrame:NSInsetRect(_buttonFrame, SLHSideMargin, 3) inView:self];
    }
    
#ifdef DEBUG_DISCLOSUREVIEW_DRAWING
    [[NSColor magentaColor] set];
    NSFrameRect(_buttonFrame);
    [[NSColor redColor] set];
    NSFrameRect(self.bounds);
#endif
}


#pragma mark - Events

- (void)mouseDown:(NSEvent *)event {

    NSPoint event_location = event.locationInWindow;
    NSPoint local_point = [self convertPoint:event_location fromView:nil];

    if ([self mouse:local_point inRect:_buttonFrame]) {

        if (_closed) {
            _buttonCell.stringValue = @"Hide";
            _closed = NO;
        } else {
            _buttonCell.stringValue = @"Show";
            _closed = YES;
        }
        
        [self updateButtonFrame];
        self.needsDisplay = YES;
        
        if (_actionIMP) {
            _actionIMP(_target, _action, self);
        }
    }
}

- (void)mouseEntered:(NSEvent *)event {
    _mouseIn = YES;
    self.needsDisplay = YES;
}

- (void)mouseExited:(NSEvent *)event {
    _mouseIn = NO;
    self.needsDisplay = YES;
}

@end

#pragma mark - 
#pragma mark **** SLHDisclosureView ****

@interface SLHDisclosureView () {
    SLHDisclosureHeaderView *_headerView;
    NSView *_contentView;
    NSSize _savedSize;
}

@end

@implementation SLHDisclosureView

#pragma mark - Initialization

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
    NSRect frame = self.frame;
    NSRect headerFrame = NSMakeRect(0, NSHeight(frame) - SLHHeaderHeight, NSWidth(frame), SLHHeaderHeight);
    _headerView = [[SLHDisclosureHeaderView alloc] initWithFrame:headerFrame];
    _headerView.autoresizingMask =  NSViewMinXMargin | NSViewMinYMargin | NSViewWidthSizable;
    _headerView.action = @selector(toggleView:);
    _headerView.target = self;

    [self addSubview:_headerView];
    _savedSize = headerFrame.size;

}

#pragma mark - Methods

- (NSString *)title {
    return _headerView->_titleCell.stringValue;
}

- (void)setTitle:(NSString *)title {
    _headerView->_titleCell.stringValue = title;
}

- (void)setContentView:(NSView *)contentView {
    [_contentView removeFromSuperview];
    _contentView = contentView;
    
    if (contentView != nil) {
        
        NSRect contentFrame = _contentView.frame;
        NSRect frame = self.frame;
        contentFrame.size.width = NSWidth(frame);
        frame.size.height = NSHeight(contentFrame) + SLHHeaderHeight;
        frame = update_frame_origin(frame.size, frame);
        self.frame = frame;
        _contentView.frame = contentFrame;
        [self addSubview:_contentView];
        
    }
}

- (void)toggleView:(id)sender {
    
    if (_headerView->_closed) {
        
        NSRect newFrame = self.frame;
        NSRect oldFrame = newFrame;
        newFrame = update_frame_origin(_savedSize, oldFrame);
        _savedSize = oldFrame.size;
        self.frame = newFrame;
        self.contentView.hidden = YES;
        [_delegate disclosureView:self didChangeRect:oldFrame toRect:newFrame];
    } else {
        NSRect oldFrame = self.frame;
        NSRect newFrame = update_frame_origin(_savedSize, oldFrame);
        _savedSize = oldFrame.size;
        self.frame = newFrame;
        self.contentView.hidden = NO;
        [_delegate disclosureView:self didChangeRect:oldFrame toRect:newFrame];
    }
}

static NSRect update_frame_origin(NSSize newSize, NSRect oldFrame) {
    CGFloat yOffset = newSize.height - NSHeight(oldFrame);
    oldFrame.origin.y -= yOffset;
    oldFrame.size = newSize;
    return oldFrame;
}

#pragma mark - Overrides

- (void)drawRect:(NSRect)dirtyRect {

    NSRect frame = self.bounds;
    frame.size.height -= SLHHeaderHeight;
    
#ifdef DEBUG_DISCLOSUREVIEW_DRAWING
    [[NSColor greenColor] set];
    NSFrameRect(frame);
#endif
    
    frame.size.height = 1;
    [[NSColor controlShadowColor] set];
    NSFrameRect(frame);
}

- (void)setFrame:(NSRect)frame {
    _savedSize.width = NSWidth(frame);
    [super setFrame:frame];
}

@end
