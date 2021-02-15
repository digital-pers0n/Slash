//
//  SLHOutputNameController.m
//  Slash
//
//  Created by Terminator on 2020/04/14.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLHOutputNameController.h"
#import "SLTDefines.h"
#import "SLTObserver.h"
#import "NSNotificationCenter+SLTAdditions.h"

static const CGFloat kMinOutputNameTextFieldWidth = 100.0;

#pragma mark - **** SLHOutputNameContainerView Class ****

@interface SLHOutputNameContainerView : NSView {
    CGFloat _containerWidth;
    CGFloat _constantWidth;
    NSSize _maxOutputNameTextSize;

    __unsafe_unretained IBOutlet NSTextField *_outputNameTextField;
    __unsafe_unretained IBOutlet NSTextField *_leftTextField;
    __unsafe_unretained IBOutlet NSButton * _leftButton;
    __unsafe_unretained IBOutlet NSTextField *_rightTextField;
    __unsafe_unretained IBOutlet NSButton * _rightButton;

}
@end

@implementation SLHOutputNameContainerView

#pragma mark - Methods

- (void)adjustSubviews {

    const CGFloat containerWidth = _containerWidth;
    const CGFloat constantWidth = _constantWidth;
    
    NSRect middleRect;
    middleRect.size = _maxOutputNameTextSize;
    middleRect.origin.y = NSMinY(_outputNameTextField.frame);
    
    if (containerWidth < constantWidth + NSWidth(middleRect)) {
        middleRect.size.width = containerWidth - constantWidth;
    }
    
    CGFloat x = round((containerWidth - NSWidth(middleRect)) * 0.5);
    middleRect.origin.x = x;
    _outputNameTextField.frame = middleRect;
    
    NSRect rect = _leftTextField.frame;
    rect.origin.x = x = NSMinX(middleRect) - NSWidth(rect);
    [_leftTextField setFrameOrigin:rect.origin];
    
    rect = _leftButton.frame;
    rect.origin.x = x - NSWidth(rect);
    [_leftButton setFrameOrigin:rect.origin];
    
    rect = _rightTextField.frame;
    rect.origin.x = NSMaxX(middleRect);
    [_rightTextField setFrameOrigin:rect.origin];
    x = NSMaxX(rect);
    
    rect = _rightButton.frame;
    rect.origin.x = x;
    [_rightButton setFrameOrigin:rect.origin];
}

- (void)updateMaxOutputNameTextSize {
    NSSize size = _outputNameTextField.cell.cellSize;
    if (size.width < kMinOutputNameTextFieldWidth) {
        size.width = kMinOutputNameTextFieldWidth;
    } else {
        size.width = ceil(size.width);
    }
    _maxOutputNameTextSize = size;
}

#pragma mark - Overrides

- (void)awakeFromNib {
    _containerWidth = NSWidth(self.frame);
    [self updateMaxOutputNameTextSize];
    
    CGFloat width = NSWidth(_leftTextField.frame);
    width += NSWidth(_leftButton.frame);
    width += NSWidth(_rightTextField.frame);
    width += NSWidth(_rightButton.frame);
    _constantWidth = width;
    
    UNSAFE typeof(self) uSelf = self;
    
    static const void(^updater)(SLHOutputNameContainerView *) =
    ^(SLHOutputNameContainerView *v){
        [v updateMaxOutputNameTextSize];
        [v adjustSubviews];
    };
    
    // Receive notifications to handle user input
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self name:NSControlTextDidEndEditingNotification
             object:_outputNameTextField handler:
     ^(id  _Nullable object, NSNotification * _Nonnull notification) {
         updater(uSelf);
     }];
    
    // Observe changes to handle cases when text was updated programmatically
    [_outputNameTextField addObserver:self
                              keyPath:KEYPATH(NSTextField, objectValue)
                              options:0 handler:
    ^(id obj, NSString * _Nonnull keyPath, NSDictionary * _Nonnull change) {
        updater(uSelf);
    }];
}

- (void)setFrameSize:(NSSize)newSize {
    [super setFrameSize:newSize];
    _containerWidth = newSize.width;
    if (newSize.width > _maxOutputNameTextSize.width) {
        [self adjustSubviews];
    }
}

- (void)viewDidUnhide {
    [super viewDidUnhide];
    [self updateMaxOutputNameTextSize];
    [self adjustSubviews];
}

- (void)dealloc
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc unregisterObserver:self name:NSControlTextDidEndEditingNotification
                    object:_outputNameTextField];
    
    [_outputNameTextField invalidateObserver:self
                                     keyPath:KEYPATH(NSTextField, objectValue)];
}

@end

#pragma mark - **** SLHOutputNameController Class ****

@interface SLHOutputNameController ()

@end

@implementation SLHOutputNameController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (IBAction)selectNext:(id)sender {
    [_encoderItemsArrayController selectNext:nil];
}

- (IBAction)selectPrevious:(id)sender {
    [_encoderItemsArrayController selectPrevious:nil];
}

@end
