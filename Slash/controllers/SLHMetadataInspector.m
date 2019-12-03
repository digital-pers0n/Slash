//
//  SLHMetadataInspector.m
//  Slash
//
//  Created by Terminator on 2019/11/17.
//  Copyright © 2019年 digital-pers0n. All rights reserved.
//

#import "SLHMetadataInspector.h"
#import "SLHStackView.h"
#import "SLHDisclosureView.h"
#import "SLHEncoderItem.h"
#import "SLHEncoderItemMetadata.h"

@interface SLHMetadataInspector () {
    
    IBOutlet SLHStackView *_stackView;
    IBOutlet SLHDisclosureView *_titleView;
    IBOutlet SLHDisclosureView *_artistView;
    IBOutlet SLHDisclosureView *_commentView;
    IBOutlet SLHDisclosureView *_dateView;
}

@end

@implementation SLHMetadataInspector

#pragma mark - Initialization

+ (instancetype)metadataInspector {
    static dispatch_once_t onceToken;
    static id obj = nil;
    
    dispatch_once(&onceToken, ^{
        obj = [[SLHMetadataInspector alloc] init];
    });
    return obj;
}

#pragma mark - Overrides 


- (void)viewDidLoad {
    [super viewDidLoad];
    [_stackView addSubview:_titleView];
    [_stackView addSubview:_artistView];
    [_stackView addSubview:_commentView];
    [_stackView addSubview:_dateView];
}



@end
