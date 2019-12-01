//
//  SLHTrimTableCellView.h
//  Slash
//
//  Created by Terminator on 2019/11/06.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class SLHTrimView;

@interface SLHTrimTableCellView : NSTableCellView

@property (nonatomic, nullable) IBOutlet SLHTrimView *trimView;
@property (nonatomic, nullable) IBOutlet NSTextField *outNameTextField;

@end

NS_ASSUME_NONNULL_END
