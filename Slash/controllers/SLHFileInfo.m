//
//  SLHFileInfo.m
//  Slash
//
//  Created by Terminator on 2019/11/16.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHFileInfo.h"
#import "SLHStackView.h"
#import "SLHDisclosureView.h"
#import "MPVPlayerItem.h"
#import "MPVPlayerItemTrack.h"

@interface SLHFileInfo () {
    
    IBOutlet SLHStackView *_stackView;
    IBOutlet SLHDisclosureView *_fileInfoView;
    IBOutlet SLHDisclosureView *_streamsView;
    
    IBOutlet NSArrayController *_tracksArrayController;
    NSArray <NSString *> *_tracksDescription;
}

@property (nonatomic) NSArray <NSString *> * tracksDescription;

@end

@implementation SLHFileInfo

#pragma mark - Initialization

+ (instancetype)fileInfo {
    static dispatch_once_t onceToken;
    static SLHFileInfo *obj = nil;
    dispatch_once(&onceToken, ^{
        obj = [[SLHFileInfo alloc] init];
    });
    return obj;
}

#pragma mark - Properties

- (void)setPlayerItem:(MPVPlayerItem *)playerItem {
    if (_playerItem == playerItem) {
        return;
    }
    _playerItem = playerItem;
    if (playerItem) {
        
        NSMutableArray *infoArray = [NSMutableArray new];
        for (MPVPlayerItemTrack *track in _playerItem.tracks) {
            NSMutableString *infoString = [NSMutableString new];
            [infoString appendFormat:@"#%lu: %@, ", track.trackIndex, track.codecName];
            switch (track.mediaType) {
                case MPVMediaTypeVideo:
                    [infoString appendFormat:@"%@, %.0fx%.0f", track.pixFormatName, track.videoSize.width, track.videoSize.height];
                    break;
                    
                case MPVMediaTypeAudio:
                    [infoString appendFormat:@"%@, %lu Hz, %@", track.channelLayout, track.sampleRate, track.language];
                    break;
                    
                case MPVMediaTypeText:
                    [infoString appendFormat:@"%@", track.language];
                    break;
                    
                default:
                    [infoString appendFormat:@"%@", track.mediaTypeName];
                    
                    break;
            }
            [infoArray addObject:infoString.copy];
        }
        self.tracksDescription = infoArray.copy;
    } else {
        [_tracksArrayController removeObjects:_tracksArrayController.arrangedObjects];
    }
}

#pragma mark - Overrides

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [_stackView addSubview:_fileInfoView];
    [_stackView addSubview:_streamsView];
}

@end
