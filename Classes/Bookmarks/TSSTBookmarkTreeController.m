//
//  TSSTBookmarkTreeController.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 5/3/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TSSTBookmarkTreeController.h"


@implementation TSSTBookmarkTreeController


- (BOOL)canRemove
{
	NSArray * selection = [self selectedObjects];
	if([selection count])
	{
		id selectedObject = [selection objectAtIndex: 0];
		
		if(![[selectedObject valueForKey: @"identifier"] isEqualToString: @"item"])
		{
			return NO;
		}
	}
	
	return [super canRemove];
}



- (BOOL)canAddChild
{
	NSArray * selection = [self selectedObjects];
	if([selection count])
	{
		id selectedObject = [selection objectAtIndex: 0];
		if([[selectedObject valueForKey: @"identifier"] isEqualToString: @"history"])
		{
			return NO;
		}
	}
	
	return [super canAddChild];
}




@end
