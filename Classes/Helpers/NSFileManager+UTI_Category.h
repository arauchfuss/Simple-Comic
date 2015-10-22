//
//  NSFileManager+UTI_Category.h
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 5/23/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSFileManager (NSFileManager_UTI_Category)

+ (NSString * )universalTypeForFile:(NSString *)filename;

@end
