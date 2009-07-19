//
//  DTSessionWindow.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 7/19/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "DTSessionWindow.h"
#import "TSSTSessionWindowController.h"

@implementation DTSessionWindow

- (void)toggleToolbarShown:(id)sender
{
	[super toggleToolbarShown: sender];
	[(TSSTSessionWindowController *)[self windowController] resizeWindow];
	[(TSSTSessionWindowController *)[self windowController] resizeView];
}

@end
