//
//  TSSTSegmentedCell.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 6/14/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "TSSTSegmentedCell.h"
#import "TSSTSegmentedControl.h"
#import "TSSTImageUtilities.h"


@implementation TSSTSegmentedCell



- (void)drawSegment:(int)segment inFrame:(NSRect)frame withView:(TSSTSegmentedControl *)controlView
{
    if([controlView mouseDownSegment] == segment || [controlView selectedSegment] == segment)
    {
		[[NSColor colorWithCalibratedWhite: 0.2 alpha: 1] set];
		NSRectFill(frame);
    }
    else
    {
		[[NSColor colorWithCalibratedWhite: 0.8 alpha: 1] set];
		NSRectFill(frame);
    }
    
    /* Stroke the segment divider */
    [[NSColor colorWithCalibratedWhite: 0.8 alpha: 1] set];
	if(segment != ([controlView segmentCount] - 1))
	{
		[NSBezierPath strokeLineFromPoint: NSMakePoint( NSMaxX(frame), NSMinY(frame)) 
								  toPoint: NSMakePoint( NSMaxX(frame), NSMaxY(frame))];
	}
	
	if([controlView segmentCount] != 1)
	{
		if(segment == 0)
		{
			frame.origin.x += 2;
			frame.size.width -= 2;
		}
		else if(segment == [controlView segmentCount] - 1)
		{
			frame.size.width -= 2;
		}
	}
	
    /* If the segment is selected an alternate image is grabbed. */
    NSImage * icon = [self imageForSegment: segment];
    
    if(icon)
    {
		NSRect IconRect = NSMakeRect(0, 0, [icon size].width, [icon size].height);
        NSRect imageRect = rectWithSizeCenteredInRect([icon size], frame);
		
		NSImage * inverted = [[NSImage alloc] initWithSize: [icon size]];
		
		[inverted lockFocus];

		if([controlView mouseDownSegment] == segment || [controlView selectedSegment] == segment)
		{
			[[NSColor colorWithCalibratedWhite: 0.9 alpha: 1] set];
		}
		else
		{
			[[NSColor colorWithCalibratedWhite: 0.1 alpha: 1] set];
		}
		
		NSRectFill( IconRect );
		
		[icon drawInRect: IconRect fromRect: IconRect
			   operation: NSCompositeDestinationIn fraction: 1];
		[inverted unlockFocus];

		[inverted drawInRect: imageRect fromRect: IconRect 
				   operation: NSCompositeSourceOver fraction: 1];
		[inverted release];

    }
}


@end

