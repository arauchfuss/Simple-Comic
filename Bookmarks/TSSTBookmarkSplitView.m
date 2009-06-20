//
//  TSSTBookmarkSplitView.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 5/25/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//



#import "TSSTBookmarkSplitView.h"



@implementation TSSTBookmarkSplitView



- (void)drawDividerInRect:(NSRect)aRect
{
	aRect.size.height -= [[self window] contentBorderThicknessForEdge: NSMinYEdge];
	[[NSColor colorWithCalibratedWhite: 0.3 alpha: 1] set];
	NSRectFill(aRect);
}



- (BOOL)mouseDownCanMoveWindow
{
	return YES;
}



@end

