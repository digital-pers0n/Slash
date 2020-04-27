//
//  SLHOutputNameController.m
//  Slash
//
//  Created by Terminator on 2020/04/14.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLHOutputNameController.h"

#pragma mark - **** SLHOutputNameContainerView Class ****

@interface SLHOutputNameContainerView : NSView {
    CGFloat _containerWidth;
    CGFloat _constantWidth;
    NSSize _maxOutputNameTextSize;

    __weak IBOutlet NSTextField *_outputNameTextField;
    __weak IBOutlet NSTextField *_leftTextField;
    __weak IBOutlet NSButton * _leftButton;
    __weak IBOutlet NSTextField *_rightTextField;
    __weak IBOutlet NSButton * _rightButton;

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

- (void)didEndEditing:(NSNotification * )n {
    [self updateMaxOutputNameTextSize];
    [self adjustSubviews];
}

- (void)updateMaxOutputNameTextSize {
    const NSSize size = _outputNameTextField.cell.cellSize;
    _maxOutputNameTextSize = NSMakeSize(round(size.width), size.height);
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

    // Receive notifications to handle user input
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(didEndEditing:)
               name:NSControlTextDidEndEditingNotification
             object:_outputNameTextField];
    
    // Observe changes to handle cases when text was updated programmatically
    [_outputNameTextField addObserver:self
                           forKeyPath:@"objectValue"
                              options:NSKeyValueObservingOptionNew
                              context:&SLHOutputNameKVOContext];

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
    [nc removeObserver:self
                  name:NSControlTextDidEndEditingNotification
                object:_outputNameTextField];
    
    [_outputNameTextField removeObserver:self
                              forKeyPath:@"objectValue"
                                 context:&SLHOutputNameKVOContext];
}

#pragma mark - KVO

static char SLHOutputNameKVOContext;

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == &SLHOutputNameKVOContext) {
        [self updateMaxOutputNameTextSize];
        [self adjustSubviews];
    } else {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
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
