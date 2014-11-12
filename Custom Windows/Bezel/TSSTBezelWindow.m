//
//  TSSTBezelWindow.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 5/30/07.
//  Copyright 2007 Dancing Tortoise Software. All rights reserved.
//



#import "TSSTBezelWindow.h"
#import "TSSTImageUtilities.h"



@implementation TSSTBezelWindow



- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    self = [super initWithContentRect: contentRect styleMask: NSBorderlessWindowMask backing: bufferingType defer: flag];
    if(self)
    {
		
    }
    return self;
}



- (BOOL)canBecomeKeyWindow
{
	return YES;
}


- (void)performClose:(id)sender
{
    [[self delegate] windowShouldClose: self];
}


- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
    return ([anItem action] == @selector(performClose:)) ? YES : NO;
}


@end



@implementation TSSTBezelView



- (void)drawRect:(NSRect)aRect
{
    [[NSColor clearColor] set];
    NSRectFill(aRect);
	NSRect bounds = [self bounds];
	NSGradient * polishedGradient = [[NSGradient alloc] initWithColorsAndLocations: [NSColor colorWithDeviceWhite: 0.3 alpha: 1], 0.0,
									 [NSColor colorWithDeviceWhite: 0.25 alpha: 1], 0.5,
									 [NSColor colorWithDeviceWhite: 0.2 alpha: 1], 0.5,
									 [NSColor colorWithDeviceWhite: 0.1 alpha: 1], 1.0, nil];
	
	[polishedGradient drawInRect: bounds angle: 270];
	[polishedGradient release];
}


@end

