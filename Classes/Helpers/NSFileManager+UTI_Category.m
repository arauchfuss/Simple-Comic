//
//  NSFileManager+UTI_Category.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 5/23/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NSFileManager+UTI_Category.h"


@implementation NSFileManager (NSFileManager_UTI_Category)


+ (NSString * )universalTypeForFile:(NSString *)filename
{
    CFStringRef uti = NULL;
    FSRef fileRef;
    Boolean isDirectory;
	
    OSStatus status = FSPathMakeRef((UInt8 *)[filename fileSystemRepresentation], &fileRef, &isDirectory);
    if ( status != noErr )
	{
        return nil;
    }
	
    status = LSCopyItemAttribute(&fileRef, kLSRolesAll, kLSItemContentType, (CFTypeRef *)&uti);
    if ( status != noErr )
	{
        return nil;
    }
	
    return (NSString *)uti;
}


@end
