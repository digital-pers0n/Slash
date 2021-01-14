//
//  SLTUtils.h
//  Slash
//
//  Created by Terminator on 2020/9/12.
//  Copyright © 2020年 digital-pers0n. All rights reserved.
//

@class NSString, NSError;

/**
 Construct the path to the temporary directory.
 Must be called once per application run before calling 
 @c SLTTemporaryDirectory() function.
 @param error a pointer to an NSError instance or nil. In case of an error, 
        this pointer is set to an actual NSError object that contains the error 
        information.
 @return YES on success, otherwise NO.
 */
BOOL SLTTemporaryDirectoryInit(NSError **error);

/**
 The path to the temporary directory. 
 @return nil if @c SLTTemporaryDirectoryInit() function wasn't called previously.
 */
NSString *SLTTemporaryDirectory(void);

/** 
 Check if the file name is shorter than the allowed length defined in the 
 @c NAME_MAX constant.
 
 @param fileName the name to check. May be nil.
 @param error a pointer to an NSError instance or nil.
 @return YES if the @c fileName is valid, NO if the fileName is nil or longer 
         than allowed length. In that case the @c error is set to an appropriate 
         NSError object.
 */
BOOL SLTValidateFileName(NSString *fileName, NSError **error);

/* Below are functions for compatibility with MacOS 11, 
   since old marker constants are deprecated there. */
/** 
 Check if a given value is the no selection marker.
 */
BOOL SLTIsNoSelectionMarker(id value);

/**
 Check if a given value is the not applicable marker.
 */
BOOL SLTIsNotApplicableMarker(id value);

/*
 Return correct pasteboard names when building for macOS 11, since kUTType
 constants are soft deprecated there.
 */
NSString *const SLTPasteboardTypeFileURL();
NSString *const SLTPasteboardTypeURL();
#define kSLTTypeFileURL SLTPasteboardTypeFileURL()
#define kSLTTypeURL SLTPasteboardTypeURL()
