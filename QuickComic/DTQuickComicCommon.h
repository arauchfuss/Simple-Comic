//
//  DTQuickComicCommon.h
//  QuickComic
//
//  Created by Alexander Rauchfuss on 11/10/07.
//  Copyright 2007 Dancing Tortoise Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class XADArchive;

NS_ASSUME_NONNULL_BEGIN

NSMutableArray<NSDictionary<NSString*,id>*> * fileListForArchive(XADArchive * archive);

NSArray<NSSortDescriptor*> * fileSort(void);

NS_ASSUME_NONNULL_END
