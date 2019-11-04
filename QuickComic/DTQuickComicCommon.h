//
//  DTQuickComicCommon.h
//  QuickComic
//
//  Created by Alexander Rauchfuss on 11/10/07.
//  Copyright 2007 Dancing Tortoise Software. All rights reserved.
//

#import <Foundation/Foundation.h>
@class XADArchive;

NS_ASSUME_NONNULL_BEGIN

#ifndef __private_extern
#define __private_extern __attribute__((visibility("hidden")))
#endif

__private_extern NSMutableArray<NSDictionary<NSString*,id>*> * fileListForArchive(XADArchive * archive);

__private_extern NSArray<NSSortDescriptor*> * fileSort(void);

NS_ASSUME_NONNULL_END
