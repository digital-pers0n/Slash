//
//  SLHTemplateNameFormatter.h
//  Slash
//
//  Created by Terminator on 2020/05/26.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SLHEncoderItem;

@interface SLHTemplateNameFormatter : NSFormatter

@property (class, readonly, nonatomic) NSString * defaultTemplateFormat;
+ (BOOL)validateTemplateName:(NSString *)templateName error:(NSError **)error;

/**
 Format specifiers:
 @c %f - filename
 @c %d - date yyyymmdd_HHMMSS
 @c %D - date as seconds
 @c %r - selection range formatted as HH_MM_SS.MS e.g. 00_01_04.344-00_03_55.183
 @c %R - same as @c %r but uses unformatted time in seconds
 
 Default is "%f-%D"
 */

@property (null_resettable, nonatomic, copy) NSString * templateFormat;

- (NSString *)stringFromDocument:(SLHEncoderItem *)document;

@end

NS_ASSUME_NONNULL_END
