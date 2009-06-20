//
//  TSSTSegmentedControl.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 6/14/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "TSSTSegmentedControl.h"
#import "TSSTSegmentedCell.h"
#import "TSSTImageUtilities.h"

@implementation TSSTSegmentedControl



+ (Class)cellClass
{
	return [TSSTSegmentedCell class];
}



/* Change this to adjust the beizierpath outline and clipping path */
+ (float)cornerRadius
{
    return 4;
}



- (int)segmentAtPoint:(NSPoint) point
{
    int testSegment = 0;
    /* The first segment is longer than its returned "widthForSegment" this compensates */
    float horizontalPosition = NSMinX([self frame]) + [self widthForSegment: testSegment] + 4;
    horizontalPosition = [self segmentCount] == 1 ? horizontalPosition + 3 : horizontalPosition;
    
    while(horizontalPosition <= point.x  && ++testSegment < [self segmentCount] - 1)
    {
        horizontalPosition += [self widthForSegment: testSegment] + 1;
    }
    
    return testSegment;
}


- (int)mouseDownSegment
{
    return mouseDownSegment;
}



/* Set the button height here as segmented controls have a fixed height in IB */
- (id)initWithCoder: (NSCoder *)origCoder
{
    if([super initWithCoder: origCoder])
    {
        mouseDownSegment = -1;
		NSSize newSize = [self frame].size;
		newSize = NSMakeSize(newSize.width, 27);
		[self setFrameSize: newSize];
    }
    return self;
}



- (void)drawRect:(NSRect)rect
{
    /* Inset by 0.5 pixels to deal with anti-aliasing/co-ord system conflict */
    NSBezierPath * buttonOutline = roundedRectWithCornerRadius( NSInsetRect(rect, 1, 1), [[self class] cornerRadius]);
    /* Stroke the white highlight for recessed appearance. */
	[buttonOutline setLineWidth: 2.0];
    
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [buttonOutline addClip];
    
    /* Loops through all of the segments and tells the cell where to draw. */
    int currentSegment = 0;
    NSRect currentRect = NSMakeRect(NSMinX(rect), NSMinY(rect), 0, NSHeight(rect));
    for ( ; currentSegment < [self segmentCount]; ++currentSegment)
    {
        currentRect.origin.x += currentRect.size.width;
        currentRect.size.width = [self widthForSegment: currentSegment];
        
        if([self segmentCount] == 1)
        {
            currentRect.size.width += 6.5;
        }
        else if((currentSegment == 0) || (currentSegment == [self segmentCount] - 1))
        {
            currentRect.size.width += 3.0;
        }
        else
        {
            currentRect.size.width += 2;
        }
        
        [[self cell] drawSegment: currentSegment inFrame: currentRect withView: self];
    }
    
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    
    /* Strokes the border, concealing fill uglyness. */
    [[NSColor colorWithCalibratedWhite: 0.8 alpha: 1] set];
    [buttonOutline stroke];
}


#pragma mark Event Handling



/* Button depresses on mousedown but does not select. */
- (void)mouseDown:(NSEvent *)event
{
    mouseDownSegment = [self segmentAtPoint: [event locationInWindow]];
    [super mouseDown: event];
    mouseDownSegment = -1;
    [self setNeedsDisplay];
}



@end
