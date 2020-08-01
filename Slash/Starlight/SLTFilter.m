//
//  SLTFilter.m
//  Slash
//
//  Created by Terminator on 2020/07/30.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLTFilter.h"
#import "SLTFilterParameter.h"

@implementation SLTFilter

- (id)copyWithZone:(NSZone *)zone {
    SLTFilter *filter = [[self.class allocWithZone:zone] init];
    filter->_filterName = _filterName.copy;
    filter->_displayName = _displayName.copy;
    filter->_enabled = _enabled;
    filter->_kind = _kind;
    filter->_parameters = _parameters.copy;
    return filter;
}

- (instancetype)initWithFilterName:(NSString *)filterName
                       displayName:(NSString *)displayName
                              kind:(SLTFilterKind)kind
{
    self = [super init];
    if (self) {
        _filterName = filterName;
        _displayName = displayName;
        _kind = kind;
        _parameters = @[];
    }
    return self;
}

- (instancetype)init {
    return [self initWithFilterName:@"" displayName:@"" kind:SLTFilterKindVideo];
}

- (NSString *)stringValue {
   
    NSUInteger count = _parameters.count;
    NSString *string = nil;
    switch (count) {
        case 0:
            return _filterName;
            break;
            
        case 1:
            string = [[_parameters objectAtIndex:0] stringValue];
            break;
            
        default:
        {
            NSMutableArray *strings = [NSMutableArray array];
            
            for (SLTFilterParameter *param in _parameters) {
                [strings addObject:param.stringValue];
            }
            string = [strings componentsJoinedByString:@":"];
        }
            break;
    }
    return [NSString stringWithFormat:@"%@=%@", _filterName, string];
}

@end
