//
//  DTToolbarItems.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 7/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "DTToolbarItems.h"
#import "TSSTSessionWindowController.h"

@implementation DTPageTurnToolbarItem


-(void)validate
{
	TSSTSessionWindowController * toolbarDelegate = (TSSTSessionWindowController *)[[self toolbar] delegate];
	[(NSSegmentedControl *)[self view] setEnabled: [toolbarDelegate canTurnPageLeft] forSegment: 0];
	[(NSSegmentedControl *)[self view] setEnabled: [toolbarDelegate canTurnPageRight] forSegment: 1];
}


@end
