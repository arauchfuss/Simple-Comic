//
//  DTSessionWindow.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 7/19/09.
//  Copyright 2009 Dancing Tortoise Software. All rights reserved.
//

#import "DTSessionWindow.h"
#import "TSSTSessionWindowController.h"
#import "SimpleComicAppDelegate.h"

@implementation DTSessionWindow

@synthesize fullscreen;

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		self.fullscreen = NO;
	}
	return self;
}


- (void)toggleToolbarShown:(id)sender
{
	TSSTManagedSession * session = [(TSSTSessionWindowController *)[self windowController] session];
	if ([[session valueForKey: TSSTFullscreen] boolValue])
	{
		return;
	}
	
	[super toggleToolbarShown: sender];
	[(TSSTSessionWindowController *)[self windowController] resizeWindow];
	[(TSSTSessionWindowController *)[self windowController] resizeView];
}


- (NSRect)constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen *)screen
{
	if (self.fullscreen)
	{
		NSRect screenFrame = [[self screen] frame];
		screenFrame.size.height += [self toolbarHeight];
		frameRect = NSIntersectionRect(screenFrame, frameRect);
		return frameRect;
	}
	
	return [super constrainFrameRect: frameRect toScreen: screen];
}


- (float)toolbarHeight
{
    return NSHeight([self frame]) - NSHeight([[self contentView] frame]);
}


@end
