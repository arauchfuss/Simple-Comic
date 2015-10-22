//
//  TSSTBookmarkWindowController.h
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 5/3/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TSSTBookmarkWindowController : NSWindowController
{
	IBOutlet NSTableView		* bookmarkTableView;
	IBOutlet NSImageView		* bookmarkCover;
	IBOutlet NSScrollView		* bookmarkGroupScrollView;
	
	IBOutlet NSArrayController	* bookmarkController;
	IBOutlet NSTreeController	* bookmarkGroupController;
	
	NSPredicate * searchPredicate;
	NSString * search;
}

@property (retain) NSString * search;
@property (retain) NSPredicate * searchPredicate;

- (NSManagedObjectContext *)managedObjectContext;

- (IBAction)showBookmarks:(id)sender;
- (IBAction)openBookmark:(id)sender;


- (void)openBookmarkWithManagedObject:(NSManagedObject *)object;

@end
