//
//  DTQuickComicCommon.m
//  QuickComic
//
//  Created by Alexander Rauchfuss on 11/10/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "DTQuickComicCommon.h"
#import "TSSTSortDescriptor.h"
#import <XADMaster/XADArchive.h>


static NSArray * fileNameSort = nil;


NSMutableArray * fileListForArchive(XADArchive * archive)
{
	NSMutableArray * fileDescriptions = [[NSMutableArray alloc] init];
	
    NSDictionary * fileDescription;
    NSInteger count = [archive numberOfEntries];
    NSInteger index = 0;
    NSString * fileName;
	NSString * rawName;
    for ( ; index < count; ++index)
    {
        fileName = [archive nameOfEntry: index];
		NSString * dataString = [archive nameOfEntry: index];
		rawName = dataString;
        if([[NSImage imageFileTypes] containsObject: [fileName pathExtension]])
        {
            fileDescription = @{@"name": fileName,
								@"index": @(index),
								@"rawName": rawName};
            [fileDescriptions addObject: fileDescription];
        }
    }
    return fileDescriptions;
}


NSArray<NSSortDescriptor*> * fileSort(void)
{
    if(!fileNameSort)
    {
        TSSTSortDescriptor * sort = [[TSSTSortDescriptor alloc] initWithKey: @"name" ascending: YES];
        fileNameSort = @[sort];
    }
    
    return fileNameSort;
}

