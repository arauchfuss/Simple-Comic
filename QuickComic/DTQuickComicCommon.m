//
//  DTQuickComicCommon.m
//  QuickComic
//
//  Created by Alexander Rauchfuss on 11/10/07.
//  Copyright 2007 Dancing Tortoise Software. All rights reserved.
//

#import "DTQuickComicCommon.h"
#import "TSSTSortDescriptor.h"
#import <Cocoa/Cocoa.h>
#import <XADMaster/XADArchive.h>

static NSArray * fileNameSort = nil;

NSMutableArray<NSDictionary<NSString*,id>*> * fileListForArchive(XADArchive * archive)
{
    NSMutableArray * fileDescriptions = [[NSMutableArray alloc] initWithCapacity: [archive numberOfEntries]];

    NSInteger count = [archive numberOfEntries];
    for (NSInteger index = 0; index < count; ++index)
    {
        NSString * fileName = [archive nameOfEntry: index];
        NSString * rawName = [archive nameOfEntry: index];
        if([[NSImage imageFileTypes] containsObject: [fileName pathExtension]])
        {
            NSDictionary * fileDescription =
            @{@"name": fileName,
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
