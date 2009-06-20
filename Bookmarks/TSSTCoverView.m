//
//  TSSTCoverView.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 5/31/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//



#import "TSSTCoverView.h"


@implementation TSSTCoverView


- (void)drawRect:(NSRect)rect
{
	NSRect bounds = [self bounds];
	
	[[NSColor whiteColor] set];
	NSRectFill( bounds );
	
	[NSGraphicsContext saveGraphicsState];
		[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
		[super drawRect: rect];
	[NSGraphicsContext restoreGraphicsState];
	
	[NSBezierPath setDefaultLineWidth: 2];
	[[NSColor blackColor] set];
	[NSBezierPath strokeLineFromPoint: NSMakePoint(NSMinX(bounds), NSMaxY(bounds))
							  toPoint: NSMakePoint(NSMaxX(bounds), NSMaxY(bounds))];
}

@end
