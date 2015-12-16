//
//  TSSTInfoWindow.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 7/15/07.
//  Copyright 2007 Dancing Tortoise Software. All rights reserved.
//

#import "TSSTInfoWindow.h"
#import "TSSTImageUtilities.h"
#import "Simple_Comic-Swift.h"

@implementation TSSTInfoWindow


- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    self = [super initWithContentRect: contentRect styleMask: NSBorderlessWindowMask backing: bufferingType defer: flag];
    if(self)
    {
        [self setOpaque: NO];
        [self setIgnoresMouseEvents: YES];
    }
    return self;
}


- (void)caretAtPoint:(NSPoint)point size:(NSSize)size withLimitLeft:(CGFloat)left right:(CGFloat)right
{
    CGFloat limitWidth = right - left;
    CGFloat relativePosition = (point.x - left) / limitWidth;
    CGFloat offset = size.width * relativePosition;
	NSRect frameRect = NSMakeRect( point.x - offset - 10, point.y, size.width + 20, size.height + 25);
	
	[[self contentView] setCaretPosition: offset + 10];
    [self setFrame: frameRect display: YES animate: NO];
	[self invalidateShadow];
}


- (void)centerAtPoint:(NSPoint)center
{
    NSRect frame = [self frame];
    [self setFrameOrigin: NSMakePoint(center.x - NSWidth(frame) / 2, center.y - NSHeight(frame) / 2)];
	[self invalidateShadow];
}


- (void)resizeToDiameter:(CGFloat)diameter
{
    NSRect frame = [self frame];
	NSPoint center = NSMakePoint(NSMinX( frame ) + NSWidth(frame) / 2, NSMinY( frame ) + NSHeight(frame) / 2);
	
	[self setFrame: NSMakeRect(center.x - diameter / 2,  center.y - diameter / 2, diameter, diameter) 
		   display: YES 
		   animate: NO];
}


@end



@implementation TSSTCircularImageView



- (void)drawRect:(NSRect)rect
{
	NSRect bounds = [self bounds];
	[[NSColor clearColor] set];
    NSRectFill(bounds);
    if([self image])
    {
		NSBezierPath * circle = [NSBezierPath bezierPathWithOvalInRect: NSInsetRect(bounds,5,5)];
        [[NSColor whiteColor] set];
        [circle fill];
        [circle addClip];
		[super drawRect: rect];
    }
}



@end

