//
//  DTToolbarItems.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 7/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "DTToolbarItems.h"
#import "TSSTSessionWindowController.h"
#import "SimpleComicAppDelegate.h"


@implementation DTToolbarItem


-(void)validate
{
	[(NSControl *)[self view] setEnabled: ![[[self toolbar] delegate] pageSelectionInProgress]];
}


@end


@implementation DTPageTurnToolbarItem


-(void)validate
{
	[(NSSegmentedControl *)[self view] setEnabled: [[[self toolbar] delegate] canTurnPageLeft] forSegment: 0];
	[(NSSegmentedControl *)[self view] setEnabled: [[[self toolbar] delegate] canTurnPageRight] forSegment: 1];
	[super validate];
}


@end
