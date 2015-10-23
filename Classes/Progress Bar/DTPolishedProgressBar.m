//
//  DTPolishedProgressBar.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 11/7/09.
//  Copyright 2009 Dancing Tortoise Software. All rights reserved.
//

#import "DTPolishedProgressBar.h"
#import "TSSTImageUtilities.h"


@interface DTPolishedProgressBar ()

@property (strong, nonatomic) NSColor *backgroundColor;
@property (strong, nonatomic) NSColor *barBackgroundColor;
@property (strong, nonatomic) NSColor *barProgressColor;
@property (strong, nonatomic) NSColor *borderColor;

@end

@implementation DTPolishedProgressBar

@synthesize progressRect, horizontalMargin, leftToRight, maxValue, currentValue, numberStyle;

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [NSColor colorWithCalibratedRed: 1 green: 1 blue: 1 alpha: 0.55];
        self.barBackgroundColor = [NSColor colorWithRed:0.75 green:0.75 blue:0.75 alpha:1];
        self.barProgressColor = [NSColor colorWithDeviceRed:0.44 green:0.44 blue:0.44 alpha:1];
        self.borderColor = [NSColor colorWithRed:0 green:0 blue:0 alpha:.25];
        
		self.numberStyle = @{NSFontAttributeName: [NSFont fontWithName:@"Helvetica Neue" size:10],
							 NSForegroundColorAttributeName: [NSColor colorWithDeviceWhite: 0.2 alpha: 1]};
        
		self.horizontalMargin = 5;
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
    NSString *totalString = [@(maxValue) stringValue];
    NSString *progressString = [@(self.currentValue + 1) stringValue];
    NSString *leftString, *rightString;
    
    NSRect bounds = [self bounds];
    NSRect indicatorRect = NSMakeRect(0, NSHeight(bounds) - 9, 2, 9);
    NSRect barRect = NSMakeRect(0, NSHeight(bounds) - 5, NSWidth(bounds), 5);
    NSRect fillRect;
    
    NSSize leftSize, rightSize;
    
    // Draw background
    [self.backgroundColor set];
    NSRectFillUsingOperation(bounds, NSCompositeSourceOver);

    // Draw bar background
    [self.barBackgroundColor set];
    fillRect = barRect;
    NSRectFill(fillRect);

    // Determine label positions and progress rect size+position
    if(leftToRight)
    {
        fillRect.size.width = NSWidth(bounds) * (currentValue + 1) / maxValue;
        indicatorRect.origin.x = round(NSWidth(fillRect)-2);
        
        leftString = progressString;
        rightString = totalString;
    }
    else
    {
		fillRect.size.width = NSWidth(bounds) * (currentValue + 1) / maxValue;
		fillRect.origin.x = round(NSWidth(bounds) - NSWidth(fillRect));
        indicatorRect.origin.x = NSMinX(fillRect);
        
        leftString = totalString;
        rightString = progressString;
    }
    
    leftSize = [leftString sizeWithAttributes: self.numberStyle];
    rightSize = [leftString sizeWithAttributes: self.numberStyle];
	
    // Draw progress
    [self.barProgressColor set];
    NSRectFill(fillRect);
    
    // Draw indicator
    [[NSColor blackColor] set];
    NSRectFill(indicatorRect);

    // Draw labels
    NSRect leftStringRect = NSMakeRect(self.horizontalMargin, NSMinY(bounds), leftSize.width, 17);
	[leftString drawInRect:leftStringRect withAttributes: self.numberStyle];
    
    NSRect rightStringRect = NSMakeRect(NSWidth(bounds) - self.horizontalMargin - rightSize.width, NSMinY(bounds), rightSize.width, 17);
    [rightString drawInRect:rightStringRect withAttributes: self.numberStyle];
    
    // Draw borders
    NSRect leftBorder = NSMakeRect(0, 0, 1, NSHeight(bounds));
    NSRect rightBorder = NSMakeRect(NSWidth(bounds)-1, 0, 1, NSHeight(bounds));
    
    [self.borderColor set];
    
    NSRectFillUsingOperation(leftBorder, NSCompositeSourceOver);
    NSRectFillUsingOperation(rightBorder, NSCompositeSourceOver);
}


/*
 This method has been over-ridden to change the progressRect porperty every time the
 progress view is re-sized.
 */
- (void)setFrameSize:(NSSize)size
{
    self.progressRect = NSMakeRect(0, 0, size.width, size.height);
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
	[self removeTrackingArea: oldArea];
	
	NSTrackingArea * newArea = [[NSTrackingArea alloc] initWithRect: progressRect 
															options: [oldArea options]
															  owner: [oldArea owner]
														   userInfo: [oldArea userInfo]];
	[self addTrackingArea: newArea];
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
- (NSInteger)indexForPoint:(NSPoint)point
{
    NSInteger index;
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
