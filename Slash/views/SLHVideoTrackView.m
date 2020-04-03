//
//  SLHVideoTrackView.m
//  Slash
//
//  Created by Terminator on 2020/03/18.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLHVideoTrackView.h"

@interface SLHVideoTrackView () {
    CGFloat _imageWidth;
    CGFloat _imageHeight;
    size_t _numberOfImages;
    const void ** _imagesPtr;
}
@end

@implementation SLHVideoTrackView

- (void)setVideoFrameImages:(NSArray *)videoFrameImages {
    if (videoFrameImages == _videoFrameImages) { return; }
    if (_imagesPtr) {
        free(_imagesPtr);
    }
    if (videoFrameImages) {
        const size_t total = videoFrameImages.count;
        const void ** images;
        images = (typeof(images))malloc(total * sizeof(void *));
        CFArrayGetValues((__bridge CFArrayRef)videoFrameImages,
                         CFRangeMake(0, total), images);
        const CGImageRef image = (const CGImageRef)images[0];
        _numberOfImages = total;
        _imageWidth = CGImageGetWidth(image);
        _imageHeight = CGImageGetHeight(image);
        _imagesPtr = images;
    } else {
        _numberOfImages = 0;
        _imageWidth = 0;
        _imageHeight = 0;
        _imagesPtr = nil;
    }
    _videoFrameImages = videoFrameImages;
}

#pragma mark - Overrides

- (void)dealloc {
    if (_imagesPtr) {
        free(_imagesPtr);
    }
}

- (void)viewDidEndLiveResize {
    [super viewDidEndLiveResize];
    self.needsDisplay = YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    if (!_videoFrameImages || self.inLiveResize) { return; }

    CGFloat width = _imageWidth;
    CGFloat height = _imageHeight;
    NSSize frame = self.frame.size;
    width = round((width * frame.height) / height);
    height = frame.height;
    const size_t toDraw = frame.width / width;
    const size_t total = _numberOfImages;
    
    const CGImageRef * images = (const CGImageRef *)_imagesPtr;
    
    NSRect drawRect = NSMakeRect(0, 0, width, height);
    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
    for (size_t i = 0; i < toDraw; ++i) {
        size_t idx = (i * total) / toDraw;
        drawRect.origin.x = i * width;
        CGContextDrawImage(context, drawRect, images[idx]);
    }
    drawRect.origin.x = toDraw * width;
    CGContextDrawImage(context, drawRect, images[total - 1]);
}

@end
