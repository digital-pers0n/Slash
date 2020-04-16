//
//  SLHAttributedTimeFormatter.h
//  Slash
//
//  Created by Terminator on 2020/04/15.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLHTimeFormatter.h"

NS_ASSUME_NONNULL_BEGIN

/** 
 Same as SLHTimeFormatter, but returns an attributed string instead.
 It draws leading zeros with tertiaryLabelColor.
*/

@interface SLHAttributedTimeFormatter : SLHTimeFormatter {
    NSDictionary * _attrs;
}

@end

NS_ASSUME_NONNULL_END
