//
//  DTQuickComicCommon.m
//  QuickComic
//
//  Created by Alexander Rauchfuss on 11/10/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "DTQuickComicCommon.h"
#import "TSSTSortDescriptor.h"
#include <XADMaster/XADArchive.h>


static NSArray * fileNameSort = nil;


NSMutableArray * fileListForArchive(XADArchive * archive)
{
	NSMutableArray * fileDescriptions = [NSMutableArray array];
	
    NSDictionary * fileDescription;
    int count = [archive numberOfEntries];
    int index = 0;
    NSString * fileName;
    for ( ; index < count; ++index)
    {
        fileName = [archive nameOfEntry: index];
        if([[NSImage imageFileTypes] containsObject: [fileName pathExtension]])
        {
            fileDescription = [NSDictionary dictionaryWithObjectsAndKeys: [archive nameOfEntry: index], @"name",
                               [NSNumber numberWithInt: index], @"index", nil];
            [fileDescriptions addObject: fileDescription];
        }
    }
    return [[fileDescriptions retain] autorelease];
}


NSArray * fileSort(void)
{
    if(!fileNameSort)
    {
        TSSTSortDescriptor * sort = [[TSSTSortDescriptor alloc] initWithKey: @"name" ascending: YES];
        fileNameSort = [[NSArray alloc] initWithObjects: sort, nil];
        [sort release];
    }
    
    return fileNameSort;
}


