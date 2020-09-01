//
//  SLKDisclosureView.h
//  Slash
//
//  Created by Terminator on 2020/8/19.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLKDisclosureHeaderView : NSView
@end

@interface SLKDisclosureView : NSView {
    @package
    NSRect _currentFrame;
}

@property (nonatomic) SLKDisclosureHeaderView *headerView;
@property (nonatomic) IBInspectable NSString *title;
@property (nonatomic, nullable, weak) IBOutlet NSView *contentView;
@property (nonatomic, readonly) NSRect currentFrame;

@end

NS_ASSUME_NONNULL_END
