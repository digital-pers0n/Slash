//
//  SLHMetadataItem.h
//  Slash
//
//  Created by Terminator on 2018/08/18.
//  Copyright © 2018年 digital-pers0n. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 @class SLHMetadataItem
 
 Metadata associated with a media file or its tracks
*/

@interface SLHMetadataItem : NSObject

/**
 Identfier of the metadata item.
 */
@property NSString *identifier;

/**
 value of the metadata item.
 */
@property NSString *value;

@end
