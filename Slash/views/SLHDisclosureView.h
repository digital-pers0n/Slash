//
//  SLHDisclosureView.h
//  Slash
//
//  Created by Terminator on 2019/11/10.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SLHDisclosureViewDelegate;

//IB_DESIGNABLE
@interface SLHDisclosureView : NSView

@property (nonatomic) IBInspectable NSString *title;
@property (nonatomic, nullable) IBOutlet NSView *contentView;
@property (nonatomic, nullable, weak) id <SLHDisclosureViewDelegate> delegate;

@end

@protocol SLHDisclosureViewDelegate <NSObject>

- (void)disclosureView:(SLHDisclosureView *)view didChangeRect:(NSRect)oldFrame toRect:(NSRect)newFrame;

@end

NS_ASSUME_NONNULL_END
