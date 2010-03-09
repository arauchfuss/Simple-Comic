//
//  DTThumbnailController.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 2/28/10.
//  Copyright 2010 Dancing Tortoise Software. All rights reserved.
//

#import "DTThumbnailController.h"
#import <QuartzCore/QuartzCore.h>

#define GRIDSPACING 20
#define THUMBSIZE 128

@implementation DTThumbnailController


- (void)awakeFromNib {
	CAScrollLayer * rootLayer = [CAScrollLayer layer];
	rootLayer.delegate = self;
	[[self view] setWantsLayer: YES];
	[[self view] setLayer: rootLayer];
	rootLayer.name = @"rootLayer";
	rootLayer.frame = NSRectToCGRect([self view].frame);
	thumbnailQueue = [NSOperationQueue new];
	rootLayer.layoutManager = self;
//	[[self view] setPostsFrameChangedNotifications: YES];
//    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(rebuildGrid) name: NSViewFrameDidChangeNotification object: [self view]];
}



- (void) dealloc
{
	[thumbnailQueue release];
	[super dealloc];
}


//- (void)mouseMoved:(NSEvent *)theEvent
//{
//	CALayer * rootLayer = [[self view] layer];
//	NSPoint mouseLocation = [theEvent locationInWindow];
//	mouseLocation = [[self view] convertPoint: mouseLocation fromView: nil];
//	NSLog(NSStringFromPoint(mouseLocation));
//	CGPoint layerMouse = NSPointToCGPoint(mouseLocation);
//	CALayer * hoverLayer = [[[self view] layer] hitTest: layerMouse];
//	
//	if(hoverLayer != rootLayer && hoverLayer != nil)
//	{
//		NSInteger index = [[rootLayer sublayers] indexOfObject: hoverLayer];
//		NSLog(@"%d", index);
//	}
//}


- (void)processThumbs
{
//	NSNumber * indexNumber;
	[self normalizeThumbnailCount];
	[self rebuildGrid];
//	float scrollOrigin = NSHeight([[self view] frame]) - NSHeight([[self view] bounds] );
//	[(CAScrollLayer *)[[self view] layer] scrollToPoint: CGPointMake(0, scrollOrigin)];
//	NSInvocationOperation * thumbnailOperation;
//	NSUInteger index, count = [[[[self view] layer] sublayers] count];
//	for (index = 0; index < count; index++)
//	{
//		indexNumber = [NSNumber numberWithInteger: index];
//		thumbnailOperation = [[NSInvocationOperation alloc] initWithTarget: self selector: @selector(addThumbnailForIndex:) object: indexNumber];
//		[thumbnailQueue addOperation: thumbnailOperation];
//	}
}


- (void)normalizeThumbnailCount
{
	NSInteger difference;
	NSInteger count = 0;
	NSInteger totalCount = [[pageController content] count];
	NSInteger currentCount = [[[[self view] layer] sublayers] count];
	if (currentCount < totalCount)
	{
		CGColorRef colorRef = CGColorCreateGenericRGB(1, 1, 1, 1);
		CALayer * newLayer;
		difference = totalCount - currentCount;
		for (count; count < difference; ++count)
		{
			newLayer = [CALayer layer];
			newLayer.delegate = self;
			newLayer.contentsGravity = kCAGravityResizeAspect;
//			newLayer.shadowOpacity = 0.5;
			newLayer.backgroundColor = colorRef;
			[[[self view] layer] addSublayer: newLayer];
		}
		CGColorRelease( colorRef);
	}
	else if (currentCount > totalCount)
	{
		difference = currentCount - totalCount;
		for (count; count < difference; ++count)
		{
			[[[[[self view] layer] sublayers] objectAtIndex: (currentCount - count)] removeFromSuperlayer];
		}
	}
}


- (void)rebuildGrid
{
	NSArray * gridCells = [[[self view] layer] sublayers];
	CALayer * cell;
	NSUInteger index, count = [gridCells count];
	NSSize viewSize = [[self view] frame].size;
	NSInteger columns = floorf((viewSize.width - GRIDSPACING)/(GRIDSPACING + THUMBSIZE));
	NSInteger rows = ceilf((float)count/(float)columns);
	NSInteger horGridPosition;
	NSInteger vertGridPosition;
	float calculatedHeight = rows * (GRIDSPACING + THUMBSIZE) + GRIDSPACING;
	float liquidSpacing = (viewSize.width - (THUMBSIZE * columns)) / (columns + 1);
	
	for (index = 0; index < count; index++)
	{
		horGridPosition = index % columns;
		vertGridPosition = (index / columns) % rows;
		cell = [gridCells objectAtIndex: index];
		cell.frame = CGRectMake(liquidSpacing + horGridPosition * (liquidSpacing + THUMBSIZE), 
								viewSize.height - ((vertGridPosition + 1) * (GRIDSPACING + THUMBSIZE)),
								THUMBSIZE, THUMBSIZE);
	}
//	[(CAScrollLayer *)[[self view] layer] scrollToPoint: CGPointMake(0, calculatedHeight - viewSize.height)];

//	[[[self view] layer] setNeedsDisplay];
}



- (void)addThumbnailForIndex:(NSNumber *)index
{
	NSInteger position = [index integerValue];	
	NSImage * source = [[[pageController arrangedObjects] objectAtIndex: position] valueForKey: @"thumbnail"];
	CGImageSourceRef pageSourceRef = CGImageSourceCreateWithData( (CFDataRef)[source TIFFRepresentation],  NULL);
	CGImageRef currentImage = CGImageSourceCreateImageAtIndex(pageSourceRef, 0, NULL);
	CFRelease(pageSourceRef);
	CALayer * thumbLayer = [[[[self view] layer] sublayers] objectAtIndex: position];
	thumbLayer.backgroundColor = nil;
	thumbLayer.contents = (id)currentImage;
	CFRelease(currentImage);
}


- (void)invalidateLayoutOfLayer:(CALayer *)layer
{
	NSLog(@"invalid");

	return;
}

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
	if(layer == [[self view] layer])
	{
		NSLog(@"rebuild");
		[self rebuildGrid];
		[layer setNeedsDisplayInRect: [layer visibleRect]];
	}
}


//- (void)displayLayer:(CALayer *)layer
//{
//	NSLog(@"test");
//	if(layer != [[self view] layer])
//	{
//		NSInteger index = [[[[self view] layer] sublayers] indexOfObject: layer];
//		NSLog(@"%d", index);
//	}
//}



- (id<CAAction>) actionForLayer:(CALayer *)layer forKey:(NSString *)event
{	
	if(layer == [[self view] layer])
	{
		return (id<CAAction>)[NSNull null];
	}
//	
//	CATransition * transitionTime = [CATransition new];
//	
//	transitionTime.duration = 1;
	
	
	return nil;
}


@end
