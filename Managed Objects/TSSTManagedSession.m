//
//  TSSTManagedSession.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 2/9/08.
//  Copyright 2008 Dancing Tortoise Software. All rights reserved.
//

#import "TSSTManagedSession.h"
#import "TSSTManagedGroup.h"
#import "BDAlias.h"

@implementation TSSTManagedSession


/*	The whole point of this method is to check for files in a session.
	Making sure they are still there.  If not they are deleted. */
- (void)awakeFromFetch
{
	[super awakeFromFetch];
	TSSTManagedGroup * group;
	NSData * aliasData;
	NSString * hardPath;
	BDAlias * savedAlias;
	for (group in [self valueForKey:@"groups"])
	{
		aliasData = [group valueForKey: @"pathData"];
		if (aliasData != nil)
		{
			savedAlias = [[BDAlias alloc] initWithData: aliasData];
			hardPath = [savedAlias fullPath];
			[savedAlias release];
			if(!hardPath)
			{
				[group setValue: nil forKey: @"session"];
				[[self managedObjectContext] deleteObject: group];
			}
		}
	}
}


//- (void)savePageOrder
//{
//	NSSet * groups = [self valueForKey: @"groups"];
//}


@end
