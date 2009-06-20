//
//  TSSTFullscreenProgressBar.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 4/19/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TSSTFullscreenProgressBar.h"
#import "TSSTImageUtilities.h"

static NSDictionary * stringAttirbutes; 


@implementation TSSTFullscreenProgressBar

+ (void)initialize
{
    stringAttirbutes = [[NSDictionary dictionaryWithObjectsAndKeys: 
						 [NSFont fontWithName: @"Lucida Grande" size: 10], NSFontAttributeName,
						 [NSColor colorWithCalibratedWhite: 0.8 alpha: 1.0], NSForegroundColorAttributeName,
						 nil] retain];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setLeftToRight: YES];
        [self setFrameSize: frame.size];
		[self setHorizontalMargin: 35];
    }
    return self;
}


- (void)drawRect:(NSRect)rect
{
    /* Drawing The border and background for the progress bar. */
    /* First the high contrast gradient to make the whole thing seem sunken */
    
    /* The outline of the actual progress bar. */
    [[NSColor colorWithCalibratedWhite: 0.8 alpha: 1] set];
    [NSBezierPath setDefaultLineWidth: 2];
	[NSBezierPath setDefaultLineJoinStyle: NSRoundLineJoinStyle];
	NSBezierPath * outlinePath = roundedRectWithCornerRadius(progressRect, 3);
	[outlinePath stroke];
	
	[NSGraphicsContext saveGraphicsState];
    [[NSGraphicsContext currentContext] setShouldAntialias: NO];
	    
    /*  Now drawing the individual tick marks in the progress bar.
	 Ticks can start from the right or the left. */
    float vertMin = NSMinY(progressRect) + 4;
    float vertMax = NSMaxY(progressRect) - 4;
    float horizontalPosition;
    float cursorPos;
    [[NSColor colorWithCalibratedWhite: 0.8 alpha: 1] set];
	
    if(leftToRight)
    {
        horizontalPosition = NSMinX(progressRect) + 4;
        cursorPos = (NSMinX(progressRect) + NSWidth(progressRect) * (currentValue + 1) / maxValue);
        for ( ; horizontalPosition < cursorPos; horizontalPosition += 3)
        {
            [NSBezierPath strokeLineFromPoint: NSMakePoint(horizontalPosition, vertMin) 
                                      toPoint: NSMakePoint(horizontalPosition, vertMax)];
        }
        horizontalPosition -= 1;
    }
    else
    {
        horizontalPosition = NSMaxX(progressRect) - 4;
        cursorPos = (NSMaxX(progressRect) - NSWidth(progressRect) * (currentValue + 1) / maxValue);
        for ( ; horizontalPosition > cursorPos; horizontalPosition -= 3)
        {
            [NSBezierPath strokeLineFromPoint: NSMakePoint(horizontalPosition, vertMin) 
                                      toPoint: NSMakePoint(horizontalPosition, vertMax)];
        }
        horizontalPosition += 1;
    }
	
	[NSGraphicsContext restoreGraphicsState];

    NSBezierPath * cursor = [NSBezierPath bezierPath];
    NSPoint arrowPoint = NSMakePoint((vertMax - vertMin) / 2, (vertMax + vertMin) / 2);
    if(leftToRight)
    {
        arrowPoint.x += (horizontalPosition + 1);
    }
    else
    {
        arrowPoint.x = (horizontalPosition - arrowPoint.x - 1);
    }
	
    [cursor moveToPoint: NSMakePoint(horizontalPosition, vertMax + 1)];
    [cursor lineToPoint: NSMakePoint(horizontalPosition, vertMin - 1)];
    
    if(NSPointInRect(arrowPoint, progressRect))
    {
        [cursor lineToPoint: arrowPoint];
    }
	
    [cursor closePath];
    [cursor fill];
	
	float textWidth = [self horizontalMargin];
	NSRect bounds = [self bounds];
	
    NSRect rightStringRect = NSMakeRect(NSMaxX(progressRect), NSMinY(bounds), textWidth, NSHeight(bounds));
    NSRect leftStringRect = NSMakeRect(0, NSMinY(bounds), textWidth, NSHeight(bounds));
	
    NSString * progressString = [NSString stringWithFormat: @"%i", currentValue + 1];
    NSSize stringSize = [progressString sizeWithAttributes: stringAttirbutes];
    NSRect stringRect = rectWithSizeCenteredInRect(stringSize, leftToRight ? leftStringRect : rightStringRect );
    [progressString drawInRect: stringRect withAttributes: stringAttirbutes];
    
    NSString * totalString = [NSString stringWithFormat: @"%i", maxValue];
    stringSize = [totalString sizeWithAttributes: stringAttirbutes];
    stringRect = rectWithSizeCenteredInRect(stringSize, leftToRight ? rightStringRect : leftStringRect );
    [totalString drawInRect: stringRect withAttributes: stringAttirbutes];
}

@end
