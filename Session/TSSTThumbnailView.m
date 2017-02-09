//
//  TSSTThumbnailView.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 8/22/07.
//  Copyright 2007 Dancing Tortoise Software. All rights reserved.
//

#import "TSSTThumbnailView.h"
#import "TSSTSessionWindowController.h"
#import "TSSTImageUtilities.h"
#import "TSSTImageView.h"
#import "TSSTInfoWindow.h"


@implementation TSSTThumbnailView


- (void)awakeFromNib
{
    [[self window] makeFirstResponder: self];
    [[self window] setAcceptsMouseMovedEvents: YES];
    [thumbnailView setClears: YES];
}



- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        hoverIndex = NSNotFound;
        trackingRects = [NSMutableIndexSet new];
        trackingIndexes = [NSMutableSet new];
        threadIdent = 0;
        thumbLock = [NSLock new];
    }
    return self;
}



- (void) dealloc
{
    [thumbLock release];
    thumbLock = nil;
    [trackingRects release];
    [trackingIndexes release];
    [super dealloc];
}



- (NSRect)rectForIndex:(NSInteger)index
{
    NSRect bounds = [[[self window] screen] visibleFrame];
    float ratio = (NSHeight(bounds)) / NSWidth(bounds);
    NSInteger horCount = ceilf(sqrtf([[pageController content] count] / ratio));
    NSInteger vertCount = ceilf((float)[[pageController content] count] / (float)horCount);
    float side = NSHeight(bounds) / vertCount;
    float horSide = NSWidth(bounds) / horCount;
    NSInteger horGridPos = index % horCount;
    NSInteger vertGridPos = (index / horCount) % vertCount;
    
    NSRect thumbRect;
    if([[[dataSource session] valueForKey: @"pageOrder"] boolValue])
    {
        thumbRect = NSMakeRect(horGridPos * horSide, NSMaxY(bounds) - side - vertGridPos * side, horSide, side);
    }
    else
    {
        thumbRect = NSMakeRect(NSMaxX(bounds) - horSide - horGridPos * horSide, NSMaxY(bounds) - side - vertGridPos * side, horSide, side);
    }
    return thumbRect;
}



- (void)setDataSource:(id)source
{
    dataSource = source;
}



- (id)dataSource
{
    return dataSource;
}



- (void)removeTrackingRects
{
    [thumbnailView setImage: nil];
    hoverIndex = NSNotFound;
    NSInteger tagIndex = [trackingRects firstIndex];
    while (tagIndex != NSNotFound)
    {
        [self removeTrackingRect: tagIndex];
        tagIndex = [trackingRects indexGreaterThanIndex: tagIndex];
    }
    [trackingRects removeAllIndexes];
    [trackingIndexes removeAllObjects];
}



- (void)buildTrackingRects
{
    hoverIndex = NSNotFound;
    [self removeTrackingRects];
	NSInteger counter = 0;
	NSRect trackRect;
	NSNumber * rectIndex;
    NSInteger tagIndex;
	for (; counter < ([[pageController content] count]); ++counter)
	{
		trackRect = NSInsetRect([self rectForIndex: counter], 2, 2);
		rectIndex = @(counter);
		tagIndex = [self addTrackingRect: trackRect 
								   owner: self 
								userData: rectIndex
							assumeInside: NO];
		[trackingRects addIndex: tagIndex];
		[trackingIndexes addObject: rectIndex];
	}
    [self setNeedsDisplay: YES];
}



- (void)drawRect:(NSRect)rect
{
    NSImage * thumbnail;
    NSRect drawRect;
    NSInteger counter = 0;
    NSPoint mouse = [NSEvent mouseLocation];
    NSRect point = NSMakeRect(mouse.x, mouse.y, 6.0f, 6.0f);
    NSPoint mousePoint = [[self window] convertRectFromScreen: point].origin;
	mousePoint = [self convertPoint: mousePoint fromView: nil];
    while (counter < limit)
    {
        thumbnail = [dataSource imageForPageAtIndex: counter];
        drawRect = [self rectForIndex: counter];
        drawRect = rectWithSizeCenteredInRect([thumbnail size], NSInsetRect(drawRect, 2, 2));
        [thumbnail drawInRect: drawRect fromRect: NSZeroRect operation: NSCompositeSourceOver fraction: 1.0];
		if(NSMouseInRect(mousePoint, drawRect, NO))
		{
			hoverIndex = counter;
            [self zoomThumbnailAtIndex: hoverIndex];
		}
        ++counter;
    }
}



- (void)mouseDown:(NSEvent *)event
{
    if(hoverIndex < [[pageController content] count] && hoverIndex >= 0)
    {
        [pageController setSelectionIndex: hoverIndex];
    }
    [[self window] orderOut: self];
}



- (void)keyDown:(NSEvent *)event
{
    NSNumber * charNumber = @([[event charactersIgnoringModifiers] characterAtIndex: 0]);
    switch ([charNumber unsignedIntValue])
    {
        case 27:
            [[[self window] windowController] killTopOptionalUIElement];
            break;
        default:
            break;
    }
}



- (void)processThumbs
{
    NSAutoreleasePool * pool = [NSAutoreleasePool new];
    ++threadIdent;
    unsigned localIdent = threadIdent;
    [thumbLock lock];
    NSInteger pageCount = [[pageController content] count];
	NSAutoreleasePool * localPool = [NSAutoreleasePool new];
    limit = 0;
    while(limit < (pageCount) && 
          localIdent == threadIdent && 
          [dataSource respondsToSelector: @selector(imageForPageAtIndex:)])
    {
        [dataSource imageForPageAtIndex: limit];

        
        if(!(limit % 5))
        {
			if([[self window] isVisible])
			{
				[self setNeedsDisplay: YES];
			}
			
			[localPool release];
			localPool = [NSAutoreleasePool new];
        }
        ++limit;
    }
	[localPool release];
    [thumbLock unlock];
    [pool release];
    [self setNeedsDisplay: YES];
}



- (void)mouseEntered:(NSEvent *)theEvent
{
	hoverIndex = [(NSNumber *)[theEvent userData] integerValue];	
    if(limit == [[pageController content] count])
    {
        [NSTimer scheduledTimerWithTimeInterval: 0.05 target: self selector: @selector(dwell:) userInfo: @(hoverIndex) repeats: NO];
    }
}



- (void)mouseExited:(NSEvent *)theEvent
{
    if([(NSNumber *)[theEvent userData] integerValue] == hoverIndex)
    {
        hoverIndex = NSNotFound;
        
		[thumbnailView setImage: nil];
		[[self window] removeChildWindow: [thumbnailView window]];
		[[thumbnailView window] orderOut: self];
    }
}



- (void)dwell:(NSTimer *)timer
{
     if([[timer userInfo] integerValue] == hoverIndex)
     {
         [self zoomThumbnailAtIndex: hoverIndex];
     }
}



- (void)zoomThumbnailAtIndex:(NSInteger)index
{
    NSImage * thumb = [[pageController arrangedObjects][index] valueForKey: @"pageImage"];
	[thumbnailView setImage: thumb];
	[thumbnailView setNeedsDisplay: YES];

    NSSize imageSize = [thumb size];
    thumbnailView.imageName = [[pageController arrangedObjects][index] valueForKey: @"name"];
    NSRect indexRect = [self rectForIndex: index];
    NSRect visibleRect = [[[self window] screen] visibleFrame];
    NSPoint thumbPoint = NSMakePoint(NSMinX(indexRect) + NSWidth(indexRect) / 2,
                                     NSMinY(indexRect) + NSHeight(indexRect) / 2);
    float viewSize = 312;//[thumbnailView frame].size.width;
    float aspect = imageSize.width / imageSize.height;
    
    if(aspect <= 1)
    {
        imageSize = NSMakeSize( aspect * viewSize, viewSize);
    }
    else
    {
        imageSize = NSMakeSize( viewSize, viewSize / aspect);
    }
    
    if(thumbPoint.y + imageSize.height / 2 > NSMaxY(visibleRect))
    {
        thumbPoint.y = NSMaxY(visibleRect) - imageSize.height / 2;
    }
    else if(thumbPoint.y - imageSize.height / 2 < NSMinY(visibleRect))
    {
        thumbPoint.y = NSMinY(visibleRect) + imageSize.height / 2;
    }
    
    if(thumbPoint.x + imageSize.width / 2 > NSMaxX(visibleRect))
    {
        thumbPoint.x = NSMaxX(visibleRect) - imageSize.width / 2;
    }
    else if(thumbPoint.x - imageSize.width / 2 < NSMinX(visibleRect))
    {
        thumbPoint.x = NSMinX(visibleRect) + imageSize.width / 2;
    }
	
    [(TSSTInfoWindow *)[thumbnailView window] setFrame: NSMakeRect(thumbPoint.x - imageSize.width / 2, thumbPoint.y - imageSize.height / 2, imageSize.width, imageSize.height)
											   display: NO
											   animate: NO];
	[[self window] addChildWindow: [thumbnailView window] ordered: NSWindowAbove];
}



@end


