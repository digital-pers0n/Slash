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

@interface SLKDisclosureView : NSView

@property (nonatomic) SLKDisclosureHeaderView *headerView;
@property (nonatomic) IBInspectable NSString *title;

@end

NS_ASSUME_NONNULL_END
