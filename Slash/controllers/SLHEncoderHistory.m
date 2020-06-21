//
//  SLHEncoderHistory.m
//  Slash
//
//  Created by Terminator on 2020/01/06.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

#import "SLHEncoderHistory.h"
#import "SLHExternalPlayer.h"
#import "MPVPlayerItem.h"
#import "MPVPlayerItemTrack.h"
#import "SLHPreferences.h"
#import "SLHTimeFormatter.h"
#import "SLHBitrateFormatter.h"
#import "slh_video_frame_extractor.h"


@interface SLHEncodedItem : NSObject <NSPasteboardWriting> {
    uint64_t _bitRate;
    uint64_t _fileSize;
    NSSize _videoSize;
    double _duration;
    NSString *_codecName;
    NSString *_newPath;
}

- (instancetype)initWithPath:(NSString *)filePath log:(NSString *)encodingLog;
@property (nonatomic) NSString *filePath;
@property (nonatomic) NSString *fileName;
@property (nonatomic) NSImage *previewImage;
@property (nonatomic) NSString *log;
@property (nonatomic, readonly) NSString *fileInfo;

- (void)reload;

@end

@implementation SLHEncodedItem

- (void)setFileName:(NSString *)fileName {
    NSString *newPath;
    if (_newPath) {
        newPath = _newPath;
    } else {
        newPath = _filePath.stringByDeletingLastPathComponent;
        newPath = [newPath stringByAppendingPathComponent:fileName];
    }
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;
    if (![fm moveItemAtPath:_filePath toPath:newPath error:&error]) {
        [NSApp presentError:error];
        __weak typeof(self) obj = self;
        // In order to properly update the string value of a bound text field
        CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^{
            [obj willChangeValueForKey:@"fileName"];
            [obj didChangeValueForKey:@"fileName"];
        });
        return;
    }
    self.filePath = newPath;
}

- (NSString *)fileName {
    return _filePath.lastPathComponent;
}

- (BOOL)validateFileName:(inout NSString **)ioValue
                   error:(out NSError **)outError {
    if (*ioValue) {
        const char *bytes = (*ioValue).UTF8String;
        if (strlen(bytes) > NAME_MAX) {
            *outError = [NSError errorWithDomain:NSPOSIXErrorDomain
                                            code:ENAMETOOLONG
                                        userInfo:nil];
            return NO;
        }
        
        const char *illegalChars = "/:";
        while (*illegalChars) {
            char c = *illegalChars++;
            if (strchr(bytes, c)) {
                NSString *desc = [NSString stringWithFormat:
                                  @"File name cannot contain '%c'.", c];
                NSString *suggestion = @"Delete the invalid character.";
                id info = @{ NSLocalizedDescriptionKey            : desc,
                             NSLocalizedRecoverySuggestionErrorKey: suggestion};
                *outError =
                [NSError errorWithDomain:NSCocoaErrorDomain
                                    code:NSFileWriteInvalidFileNameError
                                userInfo:info];
                return NO;
            }
        }
        
    } else {
        id info = @{
        NSLocalizedDescriptionKey            : @"File name cannot be nil.",
        NSLocalizedRecoverySuggestionErrorKey: @"Provide a valid file name." };
        
        *outError = [NSError errorWithDomain:NSCocoaErrorDomain
                                        code:NSKeyValueValidationError
                                    userInfo:info];
        return NO;
    }
    
    NSString *newPath = _filePath.stringByDeletingLastPathComponent;
    newPath = [newPath stringByAppendingPathComponent:*ioValue];
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:newPath isDirectory:nil]) {
        id info = @{ NSFilePathErrorKey : newPath };
        *outError = [NSError errorWithDomain:NSCocoaErrorDomain
                                        code:NSFileWriteFileExistsError
                                    userInfo:info];
        return NO;
    } else {
        _newPath = newPath;
    }
    return YES;
}

- (instancetype)initWithPath:(NSString *)path log:(NSString *)encodingLog {
    self = [super init];
    if (self) {
        self.log = encodingLog.copy;
        self.filePath = path.copy;
        
        [self reload];
        
    }
    return self;
}

- (void)reload {
    MPVPlayerItem * mpvItem = [MPVPlayerItem playerItemWithPath:_filePath];
    if (mpvItem.status == MPVPlayerItemStatusReadyToPlay) {
        
        [self willChangeValueForKey:@"fileInfo"];
        _bitRate = mpvItem.bitRate;
        _duration = mpvItem.duration;
        _fileSize = mpvItem.fileSize;
        MPVPlayerItemTrack *track = mpvItem.tracks[0];
        _codecName = track.codecName;
        if (mpvItem.hasVideoStreams) {
            _videoSize = track.videoSize;
            [self generatePreview];
        } else {
            _videoSize = NSZeroSize;
            self.previewImage = nil;
        }
        [self didChangeValueForKey:@"fileInfo"];
    }
}

- (NSString *)fileInfo {
    NSMutableString *result = [NSMutableString new];
    
    NSByteCountFormatterCountStyle style = NSByteCountFormatterCountStyleBinary;
    NSString *buffer = [NSByteCountFormatter stringFromByteCount:_fileSize
                                                      countStyle:style];
    [result appendFormat:@"size: %@", buffer];
    
    if (_videoSize.width > 0 && _videoSize.height > 0) {
        [result appendFormat:@", %.0fx%.0f",
         _videoSize.width, _videoSize.height];
    }
    
    [result appendFormat:@", %@", _codecName];
    
    buffer = SLHTimeFormatterStringForDoubleValue(_duration);
    [result appendFormat:@", duration: %@", buffer];
    
    buffer = SLHBitrateFormatterStringForDoubleValue(_bitRate);
    [result appendFormat:@", bitrate: %@", buffer];
    
    return result;
}

#pragma mark - NSPasteboardWriting

- (NSArray<NSPasteboardType> *)writableTypesForPasteboard:(NSPasteboard *)pb {
    return @[NSPasteboardTypeString];
}

- (id)pasteboardPropertyListForType:(NSPasteboardType)type {
    if (type == NSPasteboardTypeString) {
        return _filePath;
    }
    return nil;
}

#pragma mark - Private

#define SLHEncoderHistoryIconWidth 240.0
#define SLHEncoderHistoryIconHeight 140.0

static NSSize iconSizeForSourceSize(NSSize sourceSize) {
    CGFloat sourceHeight = sourceSize.height;
    CGFloat sourceWidth = sourceSize.width;
    CGFloat iconHeight = SLHEncoderHistoryIconHeight;
    CGFloat iconWidth = sourceWidth * iconHeight / sourceHeight;
    return NSMakeSize(iconWidth, iconHeight);
}

- (void)generatePreview {

    __unsafe_unretained typeof(self) uSelf = self;
    const qos_class_t qos = QOS_CLASS_USER_INTERACTIVE;
    dispatch_queue_t queue = dispatch_get_global_queue(qos, 0);

    dispatch_async(queue, ^{
        CGImageRef cgImage = nil;
        
        vfe_get_keyframe(uSelf->_filePath.fileSystemRepresentation,
                         uSelf->_duration * 0.5,
                         iconSizeForSourceSize(uSelf->_videoSize),
                         &cgImage);
        
        if (!cgImage) { // Try the slower path
            SLHPreferences *prefs = [SLHPreferences preferences];
            if (prefs.hasFFmpeg) {
                NSString *ffmpegPath = prefs.ffmpegPath;
                
                vfe_get_image(ffmpegPath.fileSystemRepresentation,
                              uSelf->_duration * 0.5,
                              iconSizeForSourceSize(uSelf->_videoSize),
                              uSelf->_filePath.fileSystemRepresentation,
                              &cgImage);
            }
        }
        if (cgImage) {
            CFRunLoopRef rl = CFRunLoopGetMain();
            NSImage *image = [[NSImage alloc] initWithCGImage:cgImage
                                                         size:NSZeroSize];
            CFRunLoopPerformBlock(rl, kCFRunLoopCommonModes, ^{
                uSelf.previewImage = image;
            });
            CFRelease(cgImage);
        } else {
            NSLog(@"%@ Cannot create preview image. Invalid data.", uSelf);
        }
    });
}

@end

static NSString * const SLHEncoderHistoryPathsBinding = @"paths";

@interface SLHEncoderHistory () <NSMenuDelegate, NSTableViewDataSource> {
    IBOutlet NSArrayController *_arrayController;
    IBOutlet NSPopover *_popover;
    IBOutlet NSTextView *_logTextView;
    IBOutlet NSTableView *_tableView;
    
    NSMutableDictionary <NSString *, SLHEncodedItem *> *_items;
    NSMutableArray <SLHEncodedItem *> *_paths;
}

@property (nonatomic, readonly) NSMutableArray <SLHEncodedItem *> *paths;

@end

@implementation SLHEncoderHistory

- (NSString *)windowNibName {
    return self.className;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _paths = [NSMutableArray new];
        _items = [NSMutableDictionary new];
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    _popover.contentSize = NSMakeSize(480, 640);
    [_tableView registerForDraggedTypes:@[(id)kUTTypeURL]];
    [_tableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
}

- (void)addItemWithPath:(NSString *)path log:(NSString *)log {
    SLHEncodedItem *item = _items[path];
    if (!item) {
        item = [[SLHEncodedItem alloc] initWithPath:path log:log];
        [self willChangeValueForKey:SLHEncoderHistoryPathsBinding];
        [_paths addObject:item];
        [self didChangeValueForKey:SLHEncoderHistoryPathsBinding];
    } else {
        [item reload];
        item.log = log;
    }
    _items[path] = item;
}

#pragma mark - NSMenuDelegate

- (void)menuNeedsUpdate:(NSMenu*)menu {
    NSInteger row = _tableView.clickedRow;
    if (row >= 0 && ![_tableView isRowSelected:row]) {
        [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    }
}

#pragma mark - NSTableViewDataSource

- (id<NSPasteboardWriting>)tableView:(NSTableView *)tableView
              pasteboardWriterForRow:(NSInteger)row {
    NSString *path = _paths[row].filePath;
    path = [@"file://" stringByAppendingString:path];
    NSPasteboardItem *pbItem = [NSPasteboardItem new];
    [pbItem setString:path forType:(__bridge id)kUTTypeFileURL];
    return pbItem;
}

#pragma mark - IBActions

- (IBAction)copySelected:(id)sender {
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    [pboard clearContents];
    [pboard writeObjects:_arrayController.selectedObjects];
}

- (IBAction)copySelectedFile:(id)sender {
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    [pboard clearContents];
    NSString *path = [_arrayController.selectedObjects.firstObject filePath];
    [pboard writeObjects:@[[NSURL fileURLWithPath:path
                                      isDirectory:NO]]];
}

- (IBAction)removeSelected:(id)sender {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *selected = [_arrayController selectedObjects];
    NSMutableArray *keys = [NSMutableArray new];
    int bypassTrash = NSApp.currentEvent.modifierFlags & NSEventModifierFlagOption;
    if (bypassTrash) {
        for (SLHEncodedItem *item in selected) {
            NSString *path = item.filePath;
            [keys addObject:path];
            if (![fm removeItemAtPath:path error:&error]) {
                NSLog(@"error: %@", error.localizedDescription);
                [self presentError:error];
            }
        }
    } else {
        for (SLHEncodedItem *item in selected) {
            NSString *path = item.filePath;
            NSURL *url = [NSURL fileURLWithPath:path isDirectory:NO];
            [keys addObject:path];
            if (![fm trashItemAtURL:url resultingItemURL:nil error:&error]) {
                NSLog(@"error: %@", error.localizedDescription);
                [self presentError:error];
            }
        }
    }
    [_arrayController removeObjects:selected];
    [_items removeObjectsForKeys:keys];
}

- (IBAction)previewSelected:(id)sender {
    NSString *path = [_arrayController.selectedObjects.firstObject filePath];
    if (path) {
        SLHExternalPlayer *player = [SLHExternalPlayer defaultPlayer];
        if (player.error) {
            [self presentError:player.error];
            return;
        }
        player.url = [NSURL fileURLWithPath:path isDirectory:NO];
        [player play];
        [player orderFront];
    }
}

- (IBAction)revealSelected:(id)sender {
    NSString *path = [_arrayController.selectedObjects.firstObject filePath];
    if (path) {
        NSWorkspace *sharedWorkspace = [NSWorkspace sharedWorkspace];
        [sharedWorkspace selectFile:path inFileViewerRootedAtPath:@""];
    }
}

- (IBAction)showLog:(NSButton *)sender {
    if (_popover.shown) {
        [_popover close];
        return;
    }
    
    NSTableCellView *tcv = (id)sender.superview;
    SLHEncodedItem *item = tcv.objectValue;
    _logTextView.string = item.log;
    [_logTextView scrollToEndOfDocument:nil];
    [_popover showRelativeToRect:sender.bounds
                          ofView:sender
                   preferredEdge:NSRectEdgeMinY];
}

@end
