//
//  TSSTFullscreenProgressBar.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 4/19/08.
//  Copyright 2008 Dancing Tortoise Software. All rights reserved.
//

#import "TSSTFullscreenProgressBar.h"
#import "TSSTImageUtilities.h"

static NSDictionary * stringAttirbutes; 


@implementation TSSTFullscreenProgressBar


- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setLeftToRight: YES];
        [self setFrameSize: frame.size];
		[self setHorizontalMargin: 1];
    }
    return self;
}


- (void)drawRect:(NSRect)rect
{
	
	NSRect bounds = [self bounds];
	
	NSRect barRect = bounds;
	/* The 4 is half the height of the progress bar */
	barRect.origin.y = NSHeight(bounds)/2 - 4.5;
	barRect.origin.x = NSMinX(bounds) + 0.5;
	barRect.size.height = 8;
	barRect.size.width -= 2;
	NSRect fillRect = NSInsetRect(barRect, 1, 1);
	
	NSBezierPath * roundedMask = roundedRectWithCornerRadius(barRect, 4);
	
	[NSGraphicsContext saveGraphicsState];
//	[[NSGraphicsContext currentContext] setShouldAntialias: NO]; 
	
	NSGradient * shadowGradient = [[NSGradient alloc] initWithColorsAndLocations: [NSColor colorWithDeviceWhite: 0.3 alpha: 1], 0.0,
								   [NSColor colorWithDeviceWhite: 0.25 alpha: 1], 0.5,
								   [NSColor colorWithDeviceWhite: 0.2 alpha: 1], 0.5,
								   [NSColor colorWithDeviceWhite: 0.1 alpha: 1], 1.0, nil];
	
	
	[shadowGradient drawInBezierPath: roundedMask angle: 90];
	roundedMask = roundedRectWithCornerRadius(fillRect, 2.5);
	[roundedMask addClip];
	[[NSColor blackColor] set];
	NSRectFill(fillRect);
	
    if(leftToRight)
    {
        fillRect.size.width = NSWidth(progressRect) * (currentValue + 1) / maxValue + 8;
    }
    else
    {
		fillRect.size.width = NSWidth(progressRect) * (currentValue + 1) / maxValue + 8;
		fillRect.origin.x = NSMinX(barRect) + (NSWidth(barRect) - NSWidth(fillRect));
    }
	
//  initWithColorsAndLocations: [NSColor colorWithCalibratedRed:0.049 green:0.270 blue:0.494 alpha: 1.000], 0.0,
//	[NSColor colorWithCalibratedRed:0.105 green:0.556 blue:0.930 alpha: 1.000], 0.5,
//	[NSColor colorWithCalibratedRed:0.161 green:0.709 blue:0.975 alpha: 1.000], 0.5,
//	[NSColor colorWithCalibratedRed:0.111 green:0.560 blue:0.767 alpha: 1.000], 1.0, nil];
	NSGradient * fillGradient = [[NSGradient alloc] initWithColorsAndLocations: [NSColor colorWithDeviceWhite: 0.7 alpha: 1], 0.0,
								 [NSColor colorWithDeviceWhite: 0.75 alpha: 1], 0.5,
								 [NSColor colorWithDeviceWhite: 0.8 alpha: 1], 0.5,
								 [NSColor colorWithDeviceWhite: 0.9 alpha: 1], 1.0, nil];
	NSBezierPath * roundFill = roundedRectWithCornerRadius(fillRect, 3);

	[fillGradient drawInBezierPath: roundFill angle: 90];
	
	[fillGradient release];
	[shadowGradient release];
	
	[NSGraphicsContext restoreGraphicsState];

}

- (void)setFrameSize:(NSSize)size
{
    [self setProgressRect: NSMakeRect([self horizontalMargin] ,0, size.width, size.height)];
    [super setFrameSize: size];
}


@end
