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

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
		self.shadowGradient = [[[NSGradient alloc] initWithColorsAndLocations: [NSColor colorWithDeviceWhite: 0.3 alpha: 1], 0.0,
							   [NSColor colorWithDeviceWhite: 0.25 alpha: 1], 0.5,
							   [NSColor colorWithDeviceWhite: 0.2 alpha: 1], 0.5,
							   [NSColor colorWithDeviceWhite: 0.1 alpha: 1], 1.0, nil] autorelease];
		self.highlightColor = [NSColor colorWithCalibratedWhite: 0.88 alpha: 1];
		
		self.emptyGradient = [[[NSGradient alloc] initWithColorsAndLocations: [NSColor colorWithDeviceWhite: 0.25 alpha: 1], 0.0,
							  [NSColor colorWithDeviceWhite: 0.45 alpha: 1], 1.0, nil] autorelease];
		self.barGradient = [[[NSGradient alloc] initWithColorsAndLocations: [NSColor colorWithDeviceWhite: 0.7 alpha: 1], 0.0,
							[NSColor colorWithDeviceWhite: 0.75 alpha: 1], 0.5,
							[NSColor colorWithDeviceWhite: 0.82 alpha: 1], 0.5,
							[NSColor colorWithDeviceWhite: 0.92 alpha: 1], 1.0, nil] autorelease];
		NSShadow * stringEmboss = [NSShadow new];
		[stringEmboss setShadowColor: [NSColor colorWithDeviceWhite: 0.9 alpha: 1]];
		[stringEmboss setShadowBlurRadius: 0];
		[stringEmboss setShadowOffset: NSMakeSize(1, -1)];
		self.numberStyle = @{NSFontAttributeName: [NSFont fontWithName: @"Lucida Grande Bold" size: 10],
							 NSForegroundColorAttributeName: [NSColor colorWithDeviceWhite: 0.2 alpha: 1],
							 NSShadowAttributeName: stringEmboss};
		[stringEmboss release];
		self.horizontalMargin = 35;
		self.cornerRadius = 4.0;
        self.leftToRight = YES;
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
	[self removeTrackingArea: [self trackingAreas][0]];
	
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


/*
 Draws the progressbar.
 */
- (void)drawRect:(NSRect)rect
{
	NSRect bounds = [self bounds];
	
	[NSBezierPath setDefaultLineWidth: 1.0];
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

	[emptyGradient drawInRect: fillRect angle: 270];

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


/*
 This method has been over-ridden to change the progressRect porperty every time the
 progress view is re-sized.
 */
- (void)setFrameSize:(NSSize)size
{
    self.progressRect = NSMakeRect(self.cornerRadius + self.horizontalMargin,0, 
								   size.width - 2 * ( self.cornerRadius + self.horizontalMargin),
								   size.height);
    [super setFrameSize: size];
}



/*
 If there has been a mouse tracking area added to this view it will be updated
 every time the progress bar is re-sized.
 The tracking area is based on the progressRect property.
 */
- (void)updateTrackingAreas
{
	if([[self trackingAreas] count] == 0)
	{
		return;
	}
	
	NSTrackingArea * oldArea = [self trackingAreas][0];
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


/*
 Changes the currentValue based on where the user clicks.
 */
- (void)mouseDown:(NSEvent *)event
{
    NSPoint cursorPoint = [self convertPoint: [event locationInWindow] fromView: nil];
    if(NSMouseInRect( cursorPoint, progressRect, [self isFlipped]))
    {
		self.currentValue = [self indexForPoint: cursorPoint];
    }
}



/*
 Kind of surprised that the mouseDown event method would not refresh.  
 Not enough code to be worth abstracting.
 */
- (void)mouseDragged:(NSEvent *)event
{
    NSPoint cursorPoint = [self convertPoint: [event locationInWindow] fromView: nil];
    if(NSMouseInRect( cursorPoint, progressRect, [self isFlipped]))
    {
		self.currentValue = [self indexForPoint: cursorPoint];

        [[NSNotificationCenter defaultCenter] postNotificationName:@"SCMouseDragNotification" object:self];
    }
}


/*
 Translates a point within the view to an index between 0 and maxValue.
 Progress indicator direction affects the index.
 */
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
