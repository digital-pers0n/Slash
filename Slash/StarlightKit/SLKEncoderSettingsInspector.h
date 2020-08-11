//
//  SLKEncoderSettingsInspector.h
//  Slash
//
//  Created by Terminator on 2020/08/11.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SLKEncoderSettings;

typedef NSViewController<SLKEncoderSettings> SLKEncoderSettingsItem;

@interface SLKEncoderSettingsInspector : NSViewController

@property (nonatomic, readonly) NSArray<SLKEncoderSettingsItem *> *settings;
@property (nonatomic, readonly) SLKEncoderSettingsItem *selectedSettings;
- (void)selectSettingsAtIndex:(NSUInteger)idx;
@property (nonatomic) NSArrayController *documents;

@end

NS_ASSUME_NONNULL_END
