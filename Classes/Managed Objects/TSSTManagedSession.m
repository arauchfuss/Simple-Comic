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
	Making sure they are still there. If not they are deleted. */
- (void)awakeFromFetch
{
	[super awakeFromFetch];
    /* By calling path for all children, groups with unresolved bookmarks
     are deleted. 
     Using copy to make sure changes to groups won't cause Cocoa to complain about mutated iterators. */
	for (TSSTManagedGroup *group in [self.groups copy])
	{
		[group path];
	}
}

@end
