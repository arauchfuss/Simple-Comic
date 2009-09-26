//
//  TSSTBezelWindow.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 5/30/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//



#import "TSSTBezelWindow.h"
#import "TSSTImageUtilities.h"


@implementation TSSTBezelWindow


- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    self = [super initWithContentRect: contentRect styleMask: NSBorderlessWindowMask | NSNonactivatingPanelMask backing: bufferingType defer: flag];
    if(self)
    {
        [self setOpaque: NO];
    }
    return self;
}


@end


@implementation TSSTBezelView


- (void)drawRect:(NSRect)aRect
{
    [[NSColor clearColor] set];
    NSRectFill(aRect);

	NSRect bounds = [self bounds];
	NSBezierPath * bezelBackgroundPath = [NSBezierPath bezierPath];
	[bezelBackgroundPath moveToPoint: NSMakePoint(0,0)];
    [bezelBackgroundPath appendBezierPathWithArcFromPoint: NSMakePoint(0 , NSMaxY(bounds)) 
												  toPoint: NSMakePoint(NSMidX(bounds), NSMaxY(bounds)) 
												   radius: 5];
	[bezelBackgroundPath appendBezierPathWithArcFromPoint: NSMakePoint(NSMaxX(bounds) , NSMaxY(bounds)) 
												  toPoint: NSMakePoint(NSMaxX(bounds), NSMidY(bounds)) 
												   radius: 5];
	[bezelBackgroundPath lineToPoint: NSMakePoint(NSMaxX(bounds), NSMinY(bounds))];
    [bezelBackgroundPath closePath];
	
    [[NSColor colorWithCalibratedWhite: 0 alpha: 0.8] set];
    [bezelBackgroundPath fill];
	
	[bezelBackgroundPath addClip];
	[[NSColor colorWithCalibratedWhite: 0.8 alpha: 1] set];
	[bezelBackgroundPath setLineWidth: 3];
	[bezelBackgroundPath stroke];
	
}


@end

