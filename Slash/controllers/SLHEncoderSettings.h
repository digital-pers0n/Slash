//
//  SLHEncoderSettings.h
//  Slash
//
//  Created by Terminator on 2018/11/13.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, SLHEncoderSettingsTab) {
    SLHEncoderSettingsVideoTab,
    SLHEncoderSettingsAudioTab,
    SLHEncoderSettingsFiltersTab,
    SLHEncoderSettingsFileInfoTab,
    SLHEncoderSettingsMetadataInspectorTab
};

@protocol SLHEncoderSettingsDelegate;

@interface SLHEncoderSettings : NSViewController

@property (nullable) id <SLHEncoderSettingsDelegate> delegate;
@property (nullable, readonly) NSView *selectedView;
@property (readonly) SLHEncoderSettingsTab selectedTab;


/** Reload current tab */
- (void)reloadTab;

@end

@protocol SLHEncoderSettingsDelegate

- (NSView *)encoderSettings:(SLHEncoderSettings *)enc viewForTab:(SLHEncoderSettingsTab) tab;

@end

NS_ASSUME_NONNULL_END
