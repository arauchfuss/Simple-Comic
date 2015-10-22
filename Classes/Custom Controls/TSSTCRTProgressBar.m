//
//  TSSTCRTProgressBar.m
//  iTunesProgress
//
//  Created by Alexander Rauchfuss on 7/14/07.
//  Copyright 2007 Dancing Tortoise Software. All rights reserved.
//



#import "TSSTCRTProgressBar.h"
#import "TSSTImageUtilities.h"



static NSDictionary * stringAttirbutes; 



@implementation TSSTCRTProgressBar

@synthesize progressRect, horizontalMargin, highContrast, leftToRight, maxValue, currentValue;


+ (void)initialize
{
    stringAttirbutes = [[NSDictionary dictionaryWithObjectsAndKeys: 
        [NSFont fontWithName: @"Lucida Grande" size: 10], NSFontAttributeName,
        [NSColor colorWithCalibratedWhite: 0 alpha: 1.0], NSForegroundColorAttributeName,
        nil] retain];
}


- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
		self.highContrast = NO;
		self.horizontalMargin = 35;
        [self setLeftToRight: YES];
        [self setFrameSize: frame.size];
		[self addObserver: self forKeyPath: @"leftToRight" options: 0 context: nil];
		[self addObserver: self forKeyPath: @"currentValue" options: 0 context: nil];
		[self addObserver: self forKeyPath: @"maxValue" options: 0 context: nil];
    }
    return self;
}


- (void) dealloc
{
	[self removeObserver: self forKeyPath: @"leftToRight"];
	[self removeObserver: self forKeyPath: @"currentValue"];
	[self removeObserver: self forKeyPath: @"maxValue"];
	[self removeTrackingArea: [[self trackingAreas] objectAtIndex: 0]];

	[super dealloc];
}



- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	[self setNeedsDisplay: YES];
}



- (BOOL)mouseDownCanMoveWindow
{
	return NO;
}



- (void)drawRect:(NSRect)rect
{
    NSRect bounds = [self bounds];
    /* Drawing The border and background for the progress bar. */
    /* First the high contrast gradient to make the whole thing seem sunken */
    bounds.size.height -= 0.5;
    bounds.origin.y += 0.5;
    NSBezierPath * framePath = roundedRectWithCornerRadius(bounds, 5.0);
    [[NSColor colorWithCalibratedWhite: 0.88 alpha: 1] set];
    [framePath stroke];
    --bounds.size.height;
    ++bounds.origin.y;
    framePath = roundedRectWithCornerRadius(bounds, 4.0);;
    NSGradient * outerGradient = [[NSGradient alloc] initWithStartingColor: [NSColor colorWithCalibratedWhite: 0.8 alpha: 1] 
                                                               endingColor: [NSColor colorWithCalibratedWhite: 0.3 alpha: 1]];
    
    [outerGradient drawInBezierPath: framePath angle: 90];
    [outerGradient release];
    
    /* Next the inner fill with its slightly greenish cast. */
    NSRect innerRect = NSInsetRect(bounds, 1, 1);
    framePath = roundedRectWithCornerRadius(innerRect, 4.0);;
    NSGradient * innerGradient = [[NSGradient alloc] initWithStartingColor: [NSColor colorWithDeviceRed: 0.839 green: 0.859 blue: 0.749 alpha: 1] 
                                                               endingColor: [NSColor colorWithDeviceRed: 0.99 green: 0.99 blue: 0.91 alpha: 1]];
    [innerGradient drawInBezierPath: framePath angle: 90];
    [innerGradient release];

    [NSGraphicsContext saveGraphicsState];
    [[NSGraphicsContext currentContext] setShouldAntialias: NO];
    
    /* The outline of the actual progress bar. */
    [[NSColor colorWithCalibratedWhite: 0.1 alpha: 1.0] set];
    [NSBezierPath setDefaultLineWidth: 1];
    [NSBezierPath strokeRect: progressRect];
    
    /*  Now drawing the individual tick marks in the progress bar.
        Ticks can start from the right or the left. */
    float vertMin = NSMinY(progressRect) + 2;
    float vertMax = NSMaxY(progressRect) - 2;
    float horizontalPosition;
    float cursorPos;
    [[NSColor colorWithCalibratedWhite: 0.6 alpha: 1.0] set];
    if(leftToRight)
    {
        horizontalPosition = NSMinX(progressRect) + 2;
        cursorPos = (NSMinX(progressRect) + NSWidth(progressRect) * (currentValue + 1) / maxValue);
        for ( ; horizontalPosition < cursorPos; horizontalPosition += 2)
        {
            [NSBezierPath strokeLineFromPoint: NSMakePoint(horizontalPosition, vertMin) 
                                      toPoint: NSMakePoint(horizontalPosition, vertMax)];
        }
        horizontalPosition -= 1;
    }
    else
    {
        horizontalPosition = NSMaxX(progressRect) - 2;
        cursorPos = (NSMaxX(progressRect) - NSWidth(progressRect) * (currentValue + 1) / maxValue);
        for ( ; horizontalPosition > cursorPos; horizontalPosition -= 2)
        {
            [NSBezierPath strokeLineFromPoint: NSMakePoint(horizontalPosition, vertMin) 
                                      toPoint: NSMakePoint(horizontalPosition, vertMax)];
        }
        horizontalPosition += 1;
    }
    [NSGraphicsContext restoreGraphicsState];

    [[NSColor colorWithCalibratedWhite: 0.1 alpha: 1.0] set];
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
    NSRect leftStringRect = NSMakeRect(NSMaxX(progressRect), NSMinY(innerRect) - 1, textWidth, NSHeight(innerRect));
    NSRect rightStringRect = NSMakeRect(0, NSMinY(innerRect) - 1, textWidth, NSHeight(innerRect));

    NSString * progressString = [NSString stringWithFormat: @"%i", currentValue + 1];
    NSSize stringSize = [progressString sizeWithAttributes: stringAttirbutes];
    NSRect stringRect = rectWithSizeCenteredInRect(stringSize, leftToRight ? rightStringRect : leftStringRect);
    [progressString drawInRect: stringRect withAttributes: stringAttirbutes];
    
    NSString * totalString = [NSString stringWithFormat: @"%i", maxValue];
    stringSize = [totalString sizeWithAttributes: stringAttirbutes];
    stringRect = rectWithSizeCenteredInRect(stringSize, leftToRight ? leftStringRect : rightStringRect);
    [totalString drawInRect: stringRect withAttributes: stringAttirbutes];
}


- (void)setFrameSize:(NSSize)size
{
//    int width =  size.width - [self horizontalMargin] * 2;
//    /*  This is to make sure that the width allows the progress
//        tick marks to allign properly. */
//    if(width % 2)  
//    {
//        ++width;
//    }
//    
//    [self setProgressRect: NSMakeRect([self horizontalMargin] , 4.5, width, size.height - 9)];
    [super setFrameSize: size];
}



- (void)updateTrackingAreas
{
	NSTrackingArea * oldArea = [[self trackingAreas] objectAtIndex: 0];
	[oldArea retain];
	[self removeTrackingArea: oldArea];
	
	NSTrackingArea * newArea = [[NSTrackingArea alloc] initWithRect: progressRect 
															options: [oldArea options]
															  owner: [oldArea owner]
														   userInfo: [oldArea userInfo]];
	[oldArea release];
	[self addTrackingArea: newArea];
	[newArea release];
}


- (void)mouseDown:(NSEvent *)event
{
    int result;
    NSPoint cursorPoint = [self convertPoint: [event locationInWindow] fromView: nil];
    if(NSMouseInRect( cursorPoint, progressRect, [self isFlipped]))
    {
        result = [self indexForPoint: cursorPoint];
        [self setValue: [NSNumber numberWithInt: result] forKey: @"currentValue"];
    }
}



- (void)mouseDragged:(NSEvent *)event
{
    int result;
    NSPoint cursorPoint = [self convertPoint: [event locationInWindow] fromView: nil];
    if(NSMouseInRect( cursorPoint, progressRect, [self isFlipped]))
    {
        result = [self indexForPoint: cursorPoint];
        [self setValue: [NSNumber numberWithInt: result] forKey: @"currentValue"];
    }
}



- (int)indexForPoint:(NSPoint)point
{
    int index;
    if(leftToRight)
    {
        index = (point.x - NSMinX(progressRect)) / NSWidth(progressRect) * maxValue;
    }
    else
    {
        index = (NSMaxX(progressRect) - point.x) / NSWidth(progressRect) * maxValue;
    }
    index = index >= maxValue ? maxValue - 1 : index;
    return index;
}



@end


