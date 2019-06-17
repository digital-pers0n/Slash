//
//  SLHPresetEditor.h
//  Slash
//
//  Created by Terminator on 2019/05/25.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol SLHPresetManagerDelegate;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const SLHEncoderPresetNameKey;

@interface SLHPresetManager : NSWindowController

@property (nullable) id <SLHPresetManagerDelegate> delegate;
- (nullable NSArray <NSDictionary *> *)presetsForName:(NSString *)name;
- (void)setPresets:(NSArray <NSDictionary *> *)presets forName:(NSString *)name;
- (void)savePresets;

@end

NS_ASSUME_NONNULL_END