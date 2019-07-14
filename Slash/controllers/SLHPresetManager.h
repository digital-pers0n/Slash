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

- (instancetype)initWithPresetsPath:(NSString *)path;
@property (readonly) NSString *presetsPath;

@property (nullable) id <SLHPresetManagerDelegate> delegate;
- (nullable NSArray <NSDictionary *> *)presetsForName:(NSString *)name;
- (void)setPresets:(NSArray <NSDictionary *> *)presets forName:(NSString *)name;
- (void)setPreset:(NSDictionary *)preset forName:(NSString *)name;
- (BOOL)hasChanges;
- (void)savePresets;

- (IBAction)showPresetsWindow:(nullable id)sender;

@end

@protocol SLHPresetManagerDelegate <NSObject>

- (void)presetManager:(SLHPresetManager *)manager loadPreset:(NSDictionary *)preset forName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
