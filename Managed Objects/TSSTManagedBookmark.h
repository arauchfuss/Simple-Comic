//
//  TSSTManagedBookmark.h
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 4/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class BDAlias;

@interface TSSTManagedBookmark : NSManagedObject
{
	BDAlias * alias;
}

@property (retain) BDAlias * alias;


- (void)setFilePath:(NSString *)path;
- (NSString *)filePath;

- (NSImage *)coverImage;

@end
