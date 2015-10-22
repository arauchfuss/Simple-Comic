//
//  TSSTBookmarkTableView.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 5/9/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//


#import "TSSTBookmarkTableView.h"


@implementation TSSTBookmarkTableView


- (void)keyDown:(NSEvent *)event
{
	NSNumber * charNumber = [NSNumber numberWithUnsignedInt: [[event charactersIgnoringModifiers] characterAtIndex: 0]];
	if ([charNumber unsignedIntValue] == NSDeleteCharacter)
	{
		if([bookmarkController canRemove])
		{
			[bookmarkController remove: self];
		}
	}
	else
	{
		[super keyDown: event];
	}
}


@end
