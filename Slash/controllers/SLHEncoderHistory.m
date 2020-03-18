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
#import "slh_process.h"


@interface SLHEncodedItem : NSObject <NSPasteboardWriting> {
    uint64_t _bitRate;
    uint64_t _fileSize;
    NSSize _videoSize;
    double _duration;
    NSString *_codecName;
}

- (instancetype)initWithPath:(NSString *)filePath log:(NSString *)encodingLog;
@property (nonatomic) NSString *filePath;
@property (nonatomic) NSImage *previewImage;
@property (nonatomic) NSString *log;
@property (nonatomic, readonly) NSString *fileInfo;

- (void)reload;

@end

@implementation SLHEncodedItem

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

static void generatePreview(__unsafe_unretained SLHEncodedItem *uSelf,
                             NSString *ffmpegPath) {
    NSSize size = iconSizeForSourceSize(uSelf->_videoSize);
    char sizeStr[16];
    snprintf(sizeStr, sizeof(sizeStr), "%.0fx%.0f", size.width, size.height);
    Process ffmpeg;
    const char *const args[] = {
        ffmpegPath.UTF8String,
        "-loglevel",    "0",
        "-ss",          @(uSelf->_duration * 0.5).stringValue.UTF8String,
        "-i",           uSelf->_filePath.UTF8String,
        "-s",           sizeStr,
        "-vframes",     "1",
        "-q:v",         "3",
        "-f",           "image2pipe",
        "-",            NULL
    };
    prc_init(&ffmpeg, (char **)args);
    if (prc_launch(&ffmpeg) != 0) {
        prc_destroy(&ffmpeg);
        NSLog(@"%@ Cannot extract preview image from '%@'",
              uSelf, uSelf->_filePath);
        return;
    }
    
    const size_t block_length = 4096;
    size_t bytes_total = 0;
    size_t bytes_read = 0;
    uint8_t *frame = malloc(block_length * sizeof(uint8_t));
    
    while ((bytes_read = fread(frame + bytes_total,
                               sizeof(uint8_t),
                               block_length,
                               prc_stdout(&ffmpeg))) > 0) {
        
        bytes_total += bytes_read;
        uint8_t *tmp = realloc(frame,
                               bytes_total * sizeof(uint8_t) + block_length);
        if (!tmp) {
            NSLog(@"%@ Fatal error %s", uSelf, strerror(errno));
            prc_destroy(&ffmpeg);
            free(frame);
            return;
        }
        
        frame = tmp;
    }
    
    CFDataRef cfData = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault,
                                                   frame,
                                                   bytes_total,
                                                   kCFAllocatorMalloc);
    
    CGImageSourceRef imageSource = CGImageSourceCreateWithData(cfData, nil);
    CGImageRef cgImage = CGImageSourceCreateImageAtIndex(imageSource,
                                                         0, nil);
    if (cgImage) {
        NSImage *image = [[NSImage alloc] initWithCGImage:cgImage
                                                     size:NSZeroSize];
        CFRelease(cgImage);
        
        CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^{
            uSelf.previewImage = image;
        });
        
    } else {
        NSLog(@"%@ Cannot create preview image. Invalid data.", uSelf);
    }
    prc_destroy(&ffmpeg);
    
    if (imageSource) {
        CFRelease(imageSource);
    }
    
    if (cfData) {
        CFRelease(cfData);
    } else if (frame) {
        free(frame);
    }
}

- (void)generatePreview {
    SLHPreferences *prefs = [SLHPreferences preferences];
    if (prefs.hasFFmpeg) {
        __unsafe_unretained typeof(self) uSelf = self;
        const qos_class_t qos = QOS_CLASS_USER_INTERACTIVE;
        dispatch_queue_t queue = dispatch_get_global_queue(qos, 0);
        NSString *ffmpegPath = prefs.ffmpegPath;
        dispatch_async(queue, ^{
            generatePreview(uSelf, ffmpegPath);
        });
    }
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
    [_tableView registerForDraggedTypes:@[NSURLPboardType]];
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
