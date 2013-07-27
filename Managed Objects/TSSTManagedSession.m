//
//  TSSTManagedSession.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 2/9/08.
//  Copyright 2008 Dancing Tortoise Software. All rights reserved.
//

#import "TSSTManagedSession.h"
#import "TSSTManagedGroup.h"

@implementation TSSTManagedSession


/*	The whole point of this method is to check for files in a session.
	Making sure they are still there.  If not they are deleted. */
- (void)awakeFromFetch
{
	[super awakeFromFetch];
	TSSTManagedGroup * group;
	NSString * path;
    /* By calling path for all children, groups with unresolved bookmarks
     are deleted. */
	for (group in [self valueForKey: @"groups"])
	{
		path = [group path];
	}
}


//- (void)savePageOrder
//{
//	NSSet * groups = [self valueForKey: @"groups"];
//}


@end
