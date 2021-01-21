//
//  SLHTrimViewSettings.m
//  Slash
//
//  Created by Terminator on 2020/04/07.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLHTrimViewSettings.h"
#import "SLHTrimViewController.h"

@interface SLHTrimViewSettings () {
    __weak IBOutlet NSSlider * _verticalSlider;
    __weak IBOutlet NSSlider * _horizontalSlider;
    double _minHorizontalZoom;
    double _maxHorizontalZoom;
    double _minVerticalZoom;
    double _maxVerticalZoom;
}

@end

@implementation SLHTrimViewSettings

- (void)viewDidLoad {
    [super viewDidLoad];
    NSSlider *horizontalSlider = _verticalSlider;
    NSSlider *verticalSlider = _horizontalSlider;
    _minHorizontalZoom = horizontalSlider.minValue;
    _maxHorizontalZoom = horizontalSlider.maxValue;
    _minVerticalZoom = verticalSlider.minValue;
    _maxVerticalZoom = verticalSlider.maxValue;
}

- (IBAction)increaseVerticalSize:(id)sender {
    double value = _verticalSlider.doubleValue;
    value *= 1.02;
    if (value > _maxVerticalZoom) {
        value = _maxVerticalZoom;
    }
    _controller.verticalZoom = value;
}

- (IBAction)decreaseVerticalSize:(id)sender {
    double value = _verticalSlider.doubleValue;
    value *= 0.98;
    if (value < _minVerticalZoom) {
        value = _minVerticalZoom;
    }
    _controller.verticalZoom = value;
}

- (IBAction)increaseHorizontalSize:(id)sender {
    double value = _horizontalSlider.doubleValue;
    value *= 1.05;
    if (value > _maxHorizontalZoom) {
        value = _maxHorizontalZoom;
    }
    _controller.horizontalZoom = value;
}

- (IBAction)decreaseHorizontalSize:(id)sender {
    double value = _horizontalSlider.doubleValue;
    value *= 0.95;
    if (value < _minHorizontalZoom) {
        value = _minHorizontalZoom;
    }
    _controller.horizontalZoom = value;
}


@end
