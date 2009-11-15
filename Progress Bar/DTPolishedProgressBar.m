//
//  DTPolishedProgressBar.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 11/7/09.
//  Copyright 2009 Dancing Tortoise Software. All rights reserved.
//

#import "DTPolishedProgressBar.h"
#import "TSSTImageUtilities.h"


@implementation DTPolishedProgressBar


@synthesize progressRect, horizontalMargin, leftToRight, maxValue, currentValue, 
cornerRadius, emptyGradient, barGradient, shadowGradient, highlightColor, numberStyle;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
		self.shadowGradient = [[NSGradient alloc] initWithColorsAndLocations: [NSColor colorWithDeviceWhite: 0.3 alpha: 1], 0.0,
							   [NSColor colorWithDeviceWhite: 0.25 alpha: 1], 0.5,
							   [NSColor colorWithDeviceWhite: 0.2 alpha: 1], 0.5,
							   [NSColor colorWithDeviceWhite: 0.1 alpha: 1], 1.0, nil];
		self.highlightColor = [NSColor colorWithCalibratedWhite: 0.88 alpha: 1];
		
		self.emptyGradient = [[NSGradient alloc] initWithColorsAndLocations: [NSColor colorWithDeviceWhite: 0.25 alpha: 1], 0.0,
							  [NSColor colorWithDeviceWhite: 0.45 alpha: 1], 1.0, nil];
		self.barGradient = [[NSGradient alloc] initWithColorsAndLocations: [NSColor colorWithDeviceWhite: 0.7 alpha: 1], 0.0,
							[NSColor colorWithDeviceWhite: 0.75 alpha: 1], 0.5,
							[NSColor colorWithDeviceWhite: 0.82 alpha: 1], 0.5,
							[NSColor colorWithDeviceWhite: 0.92 alpha: 1], 1.0, nil];
		NSShadow * stringEmboss = [NSShadow new];
		[stringEmboss setShadowColor: [NSColor colorWithDeviceWhite: 0.9 alpha: 1]];
		[stringEmboss setShadowBlurRadius: 0];
		[stringEmboss setShadowOffset: NSMakeSize(1, -1)];
		self.numberStyle = [NSDictionary dictionaryWithObjectsAndKeys: 
							 [NSFont fontWithName: @"Lucida Grande Bold" size: 10], NSFontAttributeName,
							 [NSColor colorWithDeviceWhite: 0.2 alpha: 1], NSForegroundColorAttributeName,
							 stringEmboss, NSShadowAttributeName,
							 nil];
		[stringEmboss release];
		self.horizontalMargin = 35;
		self.cornerRadius = 4.0;
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
	
	[numberStyle release];
	[barGradient release];
	[emptyGradient release];
	[shadowGradient release];
	[highlightColor release];
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
	
	NSRect barRect = bounds;
	/* The 4 is half the height of the progress bar */
	barRect.origin.y = NSHeight(bounds) / 2 - 4;
	barRect.origin.x = NSMinX(bounds) + 0.5 + self.horizontalMargin;
	barRect.size.height = 8;
	barRect.size.width -= 2 * self.horizontalMargin;
	NSBezierPath * highlight = roundedRectWithCornerRadius(barRect, self.cornerRadius);
	barRect.origin.y+=0.5;
	NSRect fillRect = NSInsetRect(barRect, 1, 1);
	if(self.highlightColor)
	{
		[self.highlightColor set];
		[highlight stroke];
	}
	
	NSBezierPath * roundedMask = roundedRectWithCornerRadius(barRect, self.cornerRadius);
	
	[NSGraphicsContext saveGraphicsState];
	
	[shadowGradient drawInBezierPath: roundedMask angle: 90];
	roundedMask = roundedRectWithCornerRadius(fillRect, self.cornerRadius - 1);
	[roundedMask addClip];
//	shadowGradient = [[NSGradient alloc] initWithColorsAndLocations: [NSColor colorWithDeviceWhite: 0 alpha: 0.1], 0.0,
//					  [NSColor colorWithDeviceWhite: 0 alpha: 0.3], 1.0, nil];
	

//		fillGradient = [[NSGradient alloc] initWithColorsAndLocations: [NSColor colorWithDeviceWhite: 0.424 alpha: 1], 0.0,
//						[NSColor colorWithDeviceWhite: 0.427 alpha: 1], 1.0, nil];

	[emptyGradient drawInRect: fillRect angle: 270];

//	[shadowGradient drawInRect: fillRect angle: 90];
//	[shadowGradient release];

    if(leftToRight)
    {
        fillRect.size.width = NSWidth(progressRect) * (currentValue + 1) / maxValue + 2 * self.cornerRadius;
    }
    else
    {
		fillRect.size.width = NSWidth(progressRect) * (currentValue + 1) / maxValue + 2 * self.cornerRadius;
		fillRect.origin.x = NSMinX(barRect) + (NSWidth(barRect) - NSWidth(fillRect) - 1);
    }
	
	NSBezierPath * roundFill = roundedRectWithCornerRadius(fillRect, cornerRadius - 1);
	
	[self.barGradient drawInBezierPath: roundFill angle: 90];
	
	[NSGraphicsContext restoreGraphicsState];
	
//		stringAttirbutes = [[NSDictionary dictionaryWithObjectsAndKeys: 
//							 [NSFont fontWithName: @"Lucida Grande" size: 10], NSFontAttributeName,
//							 [NSColor colorWithDeviceWhite: 0.82 alpha: 1], NSForegroundColorAttributeName,
//							 nil] retain];


    NSRect rightStringRect = NSMakeRect(NSMaxX(progressRect) + self.cornerRadius, NSMinY(bounds), self.horizontalMargin, NSHeight(bounds));
	NSRect leftStringRect = NSMakeRect(0, NSMinY(bounds), self.horizontalMargin, NSHeight(bounds));
	NSString * totalString = [NSString stringWithFormat: @"%i", maxValue];
    NSSize stringSize = [totalString sizeWithAttributes: self.numberStyle];
    NSRect stringRect = rectWithSizeCenteredInRect(stringSize, self.leftToRight ? rightStringRect : leftStringRect);
	[totalString drawInRect: stringRect withAttributes: self.numberStyle];

	NSString * progressString = [NSString stringWithFormat: @"%i", self.currentValue + 1];
    stringSize = [progressString sizeWithAttributes: self.numberStyle];
    stringRect = rectWithSizeCenteredInRect(stringSize, self.leftToRight ? leftStringRect : rightStringRect);
    [progressString drawInRect: stringRect withAttributes: self.numberStyle];
}



- (void)setFrameSize:(NSSize)size
{
    [self setProgressRect: NSMakeRect( self.cornerRadius + self.horizontalMargin,0, 
									  size.width - 2 * ( self.cornerRadius + self.horizontalMargin), 
									  size.height)];
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
