//
//  SLHEncoderMetadata.m
//  Slash
//
//  Created by Terminator on 2019/04/30.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHEncoderItemMetadata.h"
#import "SLHMediaItem.h"
#import "SLHMetadataItem.h"
#import "SLHMetadataIdentifiers.h"
#import "MPVPlayerItem.h"
#import "MPVMetadataItem.h"

@implementation SLHEncoderItemMetadata

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    SLHEncoderItemMetadata *item = [[self.class allocWithZone:zone] init];
    item->_artist = _artist.copy;
    item->_title = _title.copy;
    item->_date = _date.copy;
    item->_comment = _comment.copy;
    return item;
}

#pragma mark - Initialization

- (instancetype)init {
    self = [super init];
    _artist = @"";
    _title = @"";
    _comment = @"";
    _date = @"";
    return self;
}

- (instancetype)initWithPlayerItem:(MPVPlayerItem *)item {
    self = [super init];
    if (self) {
        NSArray *array = item.metadata;
        NSMutableDictionary *mdata = [NSMutableDictionary new];
        for (MPVMetadataItem *m in array) {
            mdata[m.identifier.lowercaseString] = m.value;
        }
        
        NSString *value = mdata[SLHMetadataIdentifierArtist];
        if (value) {
            _artist = value;
        }
        
        value = mdata[SLHMetadataIdentifierTitle];
        if (!value) {
            value = item.url.path.lastPathComponent.stringByDeletingPathExtension;
            if (!value) {
                value = @"";
            }
        }
        _title = value;
        
        value = mdata[SLHMetadataIdentifierDate];
        if (value) {
            _date = value;
        }
        
        value = mdata[SLHMetadataIdentifierComment];
        if (value) {
            _comment = value;
        }
    }
    return self;
}

- (instancetype)initWithMediaItem:(SLHMediaItem *)item {
    self = [self init];
    if (self) {
        NSArray *array = item.metadata;
        NSMutableDictionary *mdata = [NSMutableDictionary new];
        for (SLHMetadataItem *m in array) {
            mdata[m.identifier] = m.value;
        }
        
        NSString *value = mdata[SLHMetadataIdentifierArtist];
        if (value) {
            _artist = value;
        }
        
        value = mdata[SLHMetadataIdentifierTitle];
        if (!value) {
            value = item.filePath.lastPathComponent.stringByDeletingPathExtension;
        }
        _title = value;
        
        value = mdata[SLHMetadataIdentifierDate];
        if (value) {
            _date = value;
        }
        
        value = mdata[SLHMetadataIdentifierComment];
        if (value) {
            _comment = value;
        }
    }
    return self;
}

#pragma mark - Methods

- (NSArray<NSString *> *)arguments {
    NSMutableArray *args = [NSMutableArray new];
    if (_title.length) {
        [args addObject:@"-metadata"];
        [args addObject:[NSString stringWithFormat:@"title=%@", _title]];
    }
    if (_artist.length) {
        [args addObject:@"-metadata"];
        [args addObject:[NSString stringWithFormat:@"artist=%@", _artist]];
    }
    if (_date.length) {
        [args addObject:@"-metadata"];
        [args addObject:[NSString stringWithFormat:@"date=%@", _date]];
    }
    if (_comment.length) {
        [args addObject:@"-metadata"];
        [args addObject:[NSString stringWithFormat:@"comment=%@", _comment]];
    }
    return args;
}


@end
