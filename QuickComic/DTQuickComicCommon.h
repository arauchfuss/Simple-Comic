//
//  DTQuickComicCommon.h
//  QuickComic
//
//  Created by Alexander Rauchfuss on 11/10/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.


#import <Cocoa/Cocoa.h>
@class XADArchive;

NSMutableArray<NSDictionary*> * fileListForArchive(XADArchive * archive);

NSArray<NSSortDescriptor*> * fileSort(void);

