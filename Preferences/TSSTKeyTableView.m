//
//  TSSTKeyTableView.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 1/28/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TSSTKeyTableView.h"
#import "KeyboardPrefController.h"

@implementation TSSTKeyTableView


- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
	if(![[self delegate] allowEdit])
	{
		return NO;
	}
	
//	NSLog([theEvent description]);
	NSString * firstLetter = [[theEvent characters] substringWithRange: NSMakeRange(0, 1)];
	[[self delegate] assignKey: firstLetter withModifiers: [theEvent modifierFlags]];
	[[self delegate] setAllowEdit: NO];
	[self resignFirstResponder];
	return YES;
}

@end
