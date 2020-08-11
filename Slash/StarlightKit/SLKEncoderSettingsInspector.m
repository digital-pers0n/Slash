//
//  SLKEncoderSettingsInspector.m
//  Slash
//
//  Created by Terminator on 2020/08/11.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLKEncoderSettingsInspector.h"

@interface SLKEncoderSettingsInspector ()

@property (nonatomic) id currentDocument;

@end

@implementation SLKEncoderSettingsInspector

#pragma mark - Properties

- (void)setDocuments:(NSArrayController *)documents {
    if (_documents == documents) { return; }
    if (_documents) {
        [_documents removeObserver:self
                        forKeyPath:@"selection" context:&KVOContext];
    }
    if (documents) {
        [documents addObserver:self
                    forKeyPath:@"selection"
                       options:NSKeyValueObservingOptionNew context:&KVOContext];
    }
    _documents = documents;
}

#pragma mark - KVO

static char KVOContext;

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
    if (context == &KVOContext) {
        self.currentDocument = _documents.selectedObjects.firstObject;
    } else {
        [super observeValueForKeyPath:keyPath
                             ofObject:object change:change context:context];
    }
}

#pragma mark - Overrides

- (void)dealloc {
    [_documents removeObserver:self forKeyPath:@"selection" context:&KVOContext];
}

- (NSNibName)nibName {
    return self.className;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

@end
