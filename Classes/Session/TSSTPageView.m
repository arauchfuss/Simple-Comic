/*
	Copyright (c) 2006-2009 Dancing Tortoise Software

	Permission is hereby granted, free of charge, to any person
	obtaining a copy of this software and associated documentation
	files (the "Software"), to deal in the Software without
	restriction, including without limitation the rights to use,
	copy, modify, merge, publish, distribute, sublicense, and/or
	sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following
	conditions:

	The above copyright notice and this permission notice shall be
	included in all copies or substantial portions of the Software.

	Simple Comic
	TSSTPageView.m
*/

#include <tgmath.h>
#import "TSSTPageView.h"
#import "TSSTImageUtilities.h"
#import "SimpleComicAppDelegate.h"
#import "TSSTSessionWindowController.h"
#import "TSSTManagedSession.h"

typedef NS_ENUM(int, TSSTTurn) {
	TSSTTurnNone = 0,
	TSSTTurnLeft = 1,
	TSSTTurnRight = 2,
	TSSTTurnUnknown = 3,
};

typedef NS_OPTIONS(unsigned int, TSSTArrowKeys) {
	TSSTArrowKeyUp = 1 << 0,
	TSSTArrowKeyDown = 1 << 1,
	TSSTArrowKeyLeft = 1 << 2,
	TSSTArrowKeyRight = 1 << 3,
};

typedef struct {
	CGFloat left;
	CGFloat right;
	CGFloat up;
	CGFloat down;
} PageViewDirection;


@implementation TSSTPageView {
	NSRect firstPageRect;
	NSRect secondPageRect;
	NSImage	* firstPageImage;
	NSImage	* secondPageImage;
	
	TSSTArrowKeys scrollKeys;	//!< Stores which arrow keys are currently depressed. This enables multi axis keyboard scrolling.
	NSTimer * scrollTimer;		//!< Timer that fires in between each keydown event to smooth out the scrolling.
	NSDate * interfaceDelay;
	
	PageViewDirection scrollwheel;
	
	//! This controls the drawing of the accepting drag-drop border highlighting
	BOOL acceptingDrag;
	
	/*!	While page selection is in progress this method has a value of 1 or 2.
	 The selection number coresponds to a highlighted page. */
	int pageSelection;
	/*! This is the rect describing the users page selection. */
	NSRect cropRect;
}
@synthesize imageBounds;
@synthesize rotation;
@synthesize sessionController;


- (void)awakeFromNib
{
	[super awakeFromNib];
	/* Doing this so users can drag archives into the view. */
	[self registerForDraggedTypes: @[NSFilenamesPboardType, (__bridge NSString*)kUTTypeFileURL]];
}


- (instancetype)initWithFrame:(NSRect)aRectangle;
{
	if((self = [super initWithFrame: aRectangle]))
	{
		[self setFirstPage: nil secondPageImage: nil];
		scrollKeys = 0;
		scrollwheel.left = 0;
		scrollwheel.right = 0;
		scrollwheel.up = 0;
		scrollwheel.down = 0;
		cropRect = NSZeroRect;
		firstPageRect = NSZeroRect;
		secondPageRect = NSZeroRect;
		scrollTimer = nil;
		acceptingDrag = NO;
		pageSelection = -1;
		self.acceptsTouchEvents = YES;
	}
	return self;
}


- (void) dealloc
{
	[scrollTimer invalidate];
}


- (BOOL)acceptsFirstResponder
{
	return YES;
}


- (void)setFirstPage:(NSImage *)first secondPageImage:(NSImage *)second
{
	scrollKeys = 0;
	if(first != firstPageImage)
	{
		firstPageImage = first;
		[self startAnimationForImage: firstPageImage];
	}
	
	if(second != secondPageImage)
	{
		secondPageImage = second;
		[self startAnimationForImage: secondPageImage];
	}
	
	[self resizeView];
//    [self correctViewPoint]; // Moved to sessionwindow
//	[sessionController setPageTurn: 0];
}


#pragma mark -
#pragma mark Animations


/* Animated GIF method */
- (void)startAnimationForImage:(NSImage *)image
{
	NSImageRep *testImageRep = [image bestRepresentationForRect: NSZeroRect context: [NSGraphicsContext currentContext] hints: nil];
	NSInteger frameCount;
	CGFloat frameDuration;
	NSDictionary * animationInfo;
	if([testImageRep isKindOfClass:[NSBitmapImageRep class]])
	{
		NSBitmapImageRep *testBMImageRep = (NSBitmapImageRep*)testImageRep;
		frameCount = [[testBMImageRep valueForProperty: NSImageFrameCount] integerValue];
		if(frameCount > 1)
		{
			animationInfo = @{@"imageNumber": @1,
							  @"pageImage": firstPageImage,
							  @"loopCount": [testBMImageRep valueForProperty: NSImageLoopCount]};
			frameDuration = [[testBMImageRep valueForProperty: NSImageCurrentFrameDuration] doubleValue];
			frameDuration = frameDuration > 0.1 ? frameDuration : 0.1;
			[NSTimer scheduledTimerWithTimeInterval: frameDuration
											 target: self
										   selector: @selector(animateImage:)
										   userInfo: animationInfo
											repeats: NO];
		}
	}
}


- (void)animateImage:(NSTimer *)timer
{
	NSMutableDictionary * animationInfo = [[NSMutableDictionary alloc] initWithDictionary: [timer userInfo]];
	CGFloat frameDuration;
	NSImage * pageImage = [[animationInfo valueForKey: @"imageNumber"] integerValue] == 1 ? firstPageImage : secondPageImage;
	if([animationInfo valueForKey: @"pageImage"] != pageImage || sessionController == nil)
	{
		return;
	}
	
	NSBitmapImageRep * testImageRep = (NSBitmapImageRep *)[pageImage bestRepresentationForRect: NSZeroRect context: [NSGraphicsContext currentContext] hints: nil];;
	NSInteger loopCount = [[animationInfo valueForKey: @"loopCount"] integerValue];
	NSInteger frameCount = ([[testImageRep valueForProperty: NSImageFrameCount] integerValue] - 1);
	NSInteger currentFrame = [[testImageRep valueForProperty: NSImageCurrentFrame] integerValue];
	
	currentFrame = currentFrame < frameCount ? ++currentFrame : 0;
	if(currentFrame == 0 && loopCount > 1)
	{
		--loopCount;
		[animationInfo setValue: @(loopCount) forKey: @"loopCount"];
	}
	
	[testImageRep setProperty: NSImageCurrentFrame withValue: @(currentFrame)];
	if(loopCount != 1)
	{
		frameDuration = [[testImageRep valueForProperty: NSImageCurrentFrameDuration] doubleValue];
		frameDuration = frameDuration > 0.1 ? frameDuration : 0.1;
		[NSTimer scheduledTimerWithTimeInterval: frameDuration
										 target: self selector: @selector(animateImage:)
									   userInfo: animationInfo
										repeats: NO];
	}
	
	[self setNeedsDisplay: YES];
}


#pragma mark -
#pragma mark Drag and Drop


- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	NSPasteboard *pboard = [sender draggingPasteboard];
	if([[pboard types] containsObject: NSFilenamesPboardType] || [[pboard types] containsObject: (__bridge NSString*)kUTTypeFileURL])
	{
		acceptingDrag = YES;
		[self setNeedsDisplay: YES];
		return NSDragOperationGeneric;
	}
	return NSDragOperationNone;
}


- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	NSPasteboard *pboard = [sender draggingPasteboard];
	if([[pboard types] containsObject: NSFilenamesPboardType] || [[pboard types] containsObject: (__bridge NSString*)kUTTypeFileURL])
	{
		return NSDragOperationGeneric;
	}
	return NSDragOperationNone;
}


- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    acceptingDrag = NO;
    [self setNeedsDisplay: YES];
}


- (void)draggingEnded:(id <NSDraggingInfo>)sender
{
	acceptingDrag = NO;
	[self setNeedsDisplay: YES];
}


- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	acceptingDrag = NO;
	[self setNeedsDisplay: YES];
}


- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard * pboard = [sender draggingPasteboard];
	NSString *fileURLUTI;
	if (@available(macOS 10.13, *)) {
		fileURLUTI = NSPasteboardTypeFileURL;
	} else {
		fileURLUTI = (__bridge NSString*)kUTTypeFileURL;
	}
	if([[pboard types] containsObject: fileURLUTI])
	{
		NSArray<NSURL *> * filePaths = [pboard readObjectsForClasses:@[[NSURL class]] options:@{NSPasteboardURLReadingFileURLsOnlyKey: @YES}];
		[sessionController updateSessionObject];
		[(SimpleComicAppDelegate *)[NSApp delegate] addFileURLs: filePaths toSession: [sessionController session]];
		return YES;
	}
	return NO;
}


- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard *pboard = [sender draggingPasteboard];
	if([[pboard types] containsObject: NSFilenamesPboardType] || [[pboard types] containsObject: (__bridge NSString*)kUTTypeFileURL])
	{
		return YES;
	}
	return NO;
}


#pragma mark -
#pragma mark Drawing


- (void)drawRect:(NSRect)aRect
{
	if(!firstPageImage)
	{
		return;
	}
	
	[NSGraphicsContext saveGraphicsState];
	NSRect frame = [self frame];
	[self rotationTransformWithFrame: frame];
	
	NSImageInterpolation interpolation = [self inLiveResize] || scrollKeys ? NSImageInterpolationLow : NSImageInterpolationHigh;
	[[NSGraphicsContext currentContext] setImageInterpolation: interpolation];
	
	self.layer.sublayers = nil;
	self.layer.backgroundColor = [[NSColor blackColor]CGColor];
	
	NSData *firstPageImageData = firstPageImage.TIFFRepresentation;
    CGImageSourceRef firstPageImageSource = CGImageSourceCreateWithData((__bridge CFDataRef)firstPageImageData, NULL);
    CGImageRef firstPageImageRef =  CGImageSourceCreateImageAtIndex(firstPageImageSource, 0, NULL);
	CFRelease(firstPageImageSource);

	CALayer *firstPageLayer = [CALayer layer];
	firstPageLayer.contents = (__bridge id) firstPageImageRef;
	[firstPageLayer setFrame:[self centerScanRect: firstPageRect]];
	[self.layer addSublayer:firstPageLayer];
	CFRelease(firstPageImageRef);

	if([secondPageImage isValid])
	{
		NSData *secondPageImageData = secondPageImage.TIFFRepresentation;
		CGImageSourceRef secondPageImageSource = CGImageSourceCreateWithData((__bridge CFDataRef)secondPageImageData, NULL);
		CGImageRef secondPageImageRef =  CGImageSourceCreateImageAtIndex(secondPageImageSource, 0, NULL);
		CFRelease(secondPageImageSource);
		
		CALayer *secondPageLayer = [CALayer layer];
		secondPageLayer.contents = (__bridge id) secondPageImageRef;
		[secondPageLayer setFrame:[self centerScanRect: secondPageRect]];
		[self.layer addSublayer:secondPageLayer];
		CFRelease(secondPageImageRef);
	}
	
	if (@available(macOS 10.14, *)) {
		[[NSColor.selectedContentBackgroundColor colorWithAlphaComponent:0.5] set];
	} else {
		[[NSColor colorWithCalibratedWhite: .2 alpha: 0.5] set];
	}
	NSBezierPath * highlight;
	if(!NSEqualRects(cropRect, NSZeroRect))
	{
		NSRect selection;
		if (pageSelection ==0)
		{
			selection = NSIntersectionRect(rectFromNegativeRect(cropRect), firstPageRect);
		}
		else
		{
			selection = NSIntersectionRect(rectFromNegativeRect(cropRect), secondPageRect);
		}
		
		highlight = [NSBezierPath bezierPathWithRect: selection];
		[highlight fill];
		if (@available(macOS 10.14, *)) {
			[[NSColor.controlAccentColor colorWithAlphaComponent:0.8] set];
		} else {
			[[NSColor colorWithCalibratedWhite: 1 alpha: 0.8] set];
		}
		[NSBezierPath setDefaultLineWidth: 2];
		[NSBezierPath strokeRect: selection];
	}
	else if(pageSelection == 0)
	{
		highlight = [NSBezierPath bezierPathWithRect: firstPageRect];
		[highlight fill];
	}
	else if(pageSelection == 1)
	{
		highlight = [NSBezierPath bezierPathWithRect: secondPageRect];
		[highlight fill];
	}
	
	if (@available(macOS 10.14, *)) {
		[[NSColor.selectedContentBackgroundColor colorWithAlphaComponent:0.8] set];
	} else {
		[[NSColor colorWithCalibratedWhite: .2 alpha: 0.8] set];
	}
	
	if([sessionController pageSelectionInProgress])
	{
		NSMutableParagraphStyle * style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		[style setAlignment: NSTextAlignmentCenter];
		NSDictionary * stringAttributes = @{NSFontAttributeName: [NSFont systemFontOfSize: 24],
											NSForegroundColorAttributeName: [NSColor whiteColor],
											NSParagraphStyleAttributeName: style};
		NSString * selectionText = NSLocalizedString(@"Click to select page", @"");
		if([sessionController pageSelectionCanCrop])
		{
			selectionText = [selectionText stringByAppendingString: NSLocalizedString(@"\nDrag to crop", @"")];
		}
		NSSize textSize = [selectionText sizeWithAttributes: stringAttributes];
		NSRect bezelRect = rectWithSizeCenteredInRect(textSize, imageBounds);
		NSBezierPath * bezel = roundedRectWithCornerRadius(NSInsetRect(bezelRect, -8, -4), 6);
		[bezel fill];
		[selectionText drawInRect: bezelRect withAttributes: stringAttributes];
	}
	
	[NSGraphicsContext restoreGraphicsState];
	
	if(acceptingDrag)
	{
		[NSBezierPath setDefaultLineWidth: 6];
		[[NSColor keyboardFocusIndicatorColor] set];
		[NSBezierPath strokeRect: [[self enclosingScrollView] documentVisibleRect]];
	}
}



/* This method is used to generate the composite loupe image. */
- (NSImage *)imageInRect:(NSRect)rect
{
	if(![firstPageImage isValid])
	{
		return nil;
	}
	
	NSRect imageRect = imageBounds;
	NSPoint cursorPoint = NSZeroPoint;
	/* Re-orients the rectangle based on the current page rotation */
	switch (rotation)
	{
		case 0:
			cursorPoint = NSMakePoint(NSMinX(rect) - NSMinX(imageBounds), NSMinY(rect) - NSMinY(imageBounds));
			break;
		case 1:
			cursorPoint = NSMakePoint(NSMaxY(imageBounds) - NSMinY(rect), NSMinX(rect) - NSMinX(imageBounds));
			imageRect.size.width = NSHeight(imageBounds);
			imageRect.size.height = NSWidth(imageBounds);
			break;
		case 2:
			cursorPoint = NSMakePoint(NSMaxX(imageBounds) - NSMinX(rect), NSMaxY(imageBounds) - NSMinY(rect));
			break;
		case 3:
			cursorPoint = NSMakePoint(NSMinY(rect) - NSMinY(imageBounds), NSMaxX(imageBounds) - NSMinX(rect));
			imageRect.size.width = NSHeight(imageBounds);
			imageRect.size.height = NSWidth(imageBounds);
			break;
		default:
			break;
	}
	
	CGFloat power = [[NSUserDefaults standardUserDefaults] doubleForKey: TSSTLoupePower];
	CGFloat scale;
	CGFloat remainder;
	NSRect firstFragment = NSZeroRect;
	NSRect secondFragment = NSZeroRect;
	NSSize zoomSize;
	
	if(sessionController.session.pageOrder || ![secondPageImage isValid])
	{
		scale = NSHeight(imageRect) / [firstPageImage size].height;
		zoomSize = NSMakeSize(NSWidth(rect) / (power * scale), NSHeight(rect) / (power * scale));
		firstFragment = NSMakeRect(cursorPoint.x / scale - zoomSize.width / 2,
								   cursorPoint.y / scale - zoomSize.height / 2,
								   zoomSize.width, zoomSize.height);
		remainder = NSMaxX(firstFragment) - [firstPageImage size].width;
		
		if([secondPageImage isValid] && remainder > 0)
		{
			cursorPoint.x -= [firstPageImage size].width * scale;
			scale = NSHeight(imageRect) / [secondPageImage size].height;
			zoomSize = NSMakeSize(NSWidth(rect) / (power * scale), NSHeight(rect) / (power * scale));
			secondFragment = NSMakeRect(cursorPoint.x / scale - zoomSize.width / 2,
										cursorPoint.y / scale - zoomSize.height / 2,
										zoomSize.width, zoomSize.height);
		}
	}
	else
	{
		scale = NSHeight(imageRect) / [secondPageImage size].height;
		zoomSize = NSMakeSize(NSWidth(rect) / (power * scale), NSHeight(rect) / (power * scale));
		secondFragment = NSMakeRect(cursorPoint.x / scale - zoomSize.width / 2,
									cursorPoint.y / scale - zoomSize.height / 2,
									zoomSize.width, zoomSize.height);
		remainder = NSMaxX(secondFragment) - [secondPageImage size].width;
		if(remainder > 0)
		{
			cursorPoint.x -= [secondPageImage size].width * scale;
			scale = NSHeight(imageRect) / [firstPageImage size].height;
			zoomSize = NSMakeSize(NSWidth(rect) / (power * scale), NSHeight(rect) / (power * scale));
			firstFragment = NSMakeRect(cursorPoint.x / scale - zoomSize.width / 2,
									   cursorPoint.y / scale - zoomSize.height / 2,
									   zoomSize.width, zoomSize.height);
		}
	}
	
	NSImage * imageFragment = [[NSImage alloc] initWithSize: rect.size];
	[imageFragment lockFocus];
	[self rotationTransformWithFrame: NSMakeRect(0, 0, NSWidth(rect), NSHeight(rect))];
	
	if(!NSEqualRects(firstFragment, NSZeroRect))
	{
		[firstPageImage drawInRect: NSMakeRect(0,0,NSWidth(rect), NSHeight(rect)) fromRect: firstFragment operation: NSCompositingOperationSourceOver fraction: 1.0];
	}
	
	if(!NSEqualRects(secondFragment, NSZeroRect))
	{
		[secondPageImage drawInRect: NSMakeRect(0,0,NSWidth(rect), NSHeight(rect)) fromRect: secondFragment operation: NSCompositingOperationSourceOver fraction: 1.0];
	}
	[imageFragment unlockFocus];
	return imageFragment;
}


#pragma mark -
#pragma mark Geometry handling


- (void)setRotation:(NSInteger)rot
{
	rotation = rot;
	[self resizeView];
}


- (void)rotationTransformWithFrame:(NSRect)rect
{
	NSAffineTransform * transform = [NSAffineTransform transform];
	switch (rotation)
	{
		case 1:
			[transform rotateByDegrees: 270];
			[transform translateXBy: - NSHeight(rect) yBy: 0];
			break;
		case 2:
			[transform rotateByDegrees: 180];
			[transform translateXBy: - NSWidth(rect) yBy: - NSHeight(rect)];
			break;
		case 3:
			[transform rotateByDegrees: 90];
			[transform translateXBy: 0 yBy: - NSWidth(rect)];
			break;
		default:
			break;
	}
	[transform concat];
}


/*  This fixes clipping rect of the scrollview after a page turn. */
- (void)correctViewPoint
{
	NSPoint correctOrigin = NSZeroPoint;
	NSSize frameSize = [self frame].size;
	NSSize viewSize = [[self enclosingScrollView] documentVisibleRect].size;
	if(NSEqualSizes(frameSize, NSZeroSize))
	{
		return;
	}
	
	if([sessionController pageTurn] == 1)
	{
		correctOrigin.x = (frameSize.width > viewSize.width) ? (frameSize.width - viewSize.width) : 0;
	}
	
	correctOrigin.y = (frameSize.height > viewSize.height) ? (frameSize.height - viewSize.height) : 0;
	
	NSScrollView * scrollView = [self enclosingScrollView];
	NSClipView * clipView = [scrollView contentView];
	[clipView scrollToPoint: correctOrigin];
	[scrollView reflectScrolledClipView: clipView];
}


- (NSSize)combinedImageSizeForZoom:(CGFloat)zoomScale
{
//    float zoomScale = (float)(10.0 + level) / 10.0;
	NSSize firstSize = firstPageImage ? [firstPageImage size] : NSZeroSize;
	NSSize secondSize = secondPageImage ? [secondPageImage size] : NSZeroSize;
	
	if(firstSize.height > secondSize.height)
	{
		secondSize = scaleSize(secondSize , firstSize.height / secondSize.height);
	}
	else if(firstSize.height < secondSize.height)
	{
		firstSize = scaleSize(firstSize , secondSize.height / firstSize.height);
	}
	
	firstSize.width += secondSize.width;
	
	if(rotation == 1 || rotation == 3)
	{
		firstSize = NSMakeSize(firstSize.height, firstSize.width);
	}
	
	NSSize zoomedSize = scaleSize(firstSize, zoomScale);
	return zoomedSize;
}


- (void)resizeView
{
	firstPageRect = NSZeroRect;
	secondPageRect = NSZeroRect;
	NSRect visibleRect = [[self enclosingScrollView] documentVisibleRect];
	NSRect frameRect = [self frame];
	if (frameRect.size.width <= 0 || frameRect.size.height <= 0) {
		return; //TODO: How did we get here?
	}
	CGFloat xpercent = NSMidX(visibleRect) / frameRect.size.width;
	CGFloat ypercent = NSMidY(visibleRect) / frameRect.size.height;
	NSSize imageSize = [self combinedImageSizeForZoom: sessionController.session.zoomLevel];
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	
	NSSize viewSize = NSZeroSize;
	CGFloat scaleToFit;
	NSInteger scaling = sessionController.session.scaleOptions;
	scaling = [sessionController currentPageIsText] ? 2 : scaling;
	switch (scaling)
	{
		case 0:
			viewSize.width = imageSize.width > NSWidth(visibleRect) ? imageSize.width : NSWidth(visibleRect);
			viewSize.height = imageSize.height > NSHeight(visibleRect) ? imageSize.height : NSHeight(visibleRect);
			break;
		case 1:
			viewSize = visibleRect.size;
			break;
		case 2:
			if(rotation == 1 || rotation == 3)
			{
				scaleToFit = NSHeight(visibleRect) / imageSize.height;
			}
			else
			{
				scaleToFit = NSWidth(visibleRect) / imageSize.width;
			}
			
			if([defaults boolForKey: TSSTConstrainScale])
			{
				scaleToFit = scaleToFit > 1 ? 1 : scaleToFit;
			}
			viewSize = scaleSize(imageSize, scaleToFit);
			viewSize.width = viewSize.width > NSWidth(visibleRect) ? viewSize.width : NSWidth(visibleRect);
			viewSize.height = viewSize.height > NSHeight(visibleRect) ? viewSize.height : NSHeight(visibleRect);
			break;
		default:
			break;
	}
	
	viewSize = NSMakeSize(round(viewSize.width), round(viewSize.height));
	[self setFrameSize: viewSize];
	
	if(![defaults boolForKey: TSSTConstrainScale] &&
	   sessionController.session.scaleOptions != 0 )
	{
		if( viewSize.width / viewSize.height < imageSize.width / imageSize.height)
		{
			scaleToFit = viewSize.width / imageSize.width;
		}
		else
		{
			scaleToFit = viewSize.height / imageSize.height;
		}
		imageSize = scaleSize(imageSize, scaleToFit);
	}
	
	imageBounds = rectWithSizeCenteredInRect(imageSize, NSMakeRect(0,0,viewSize.width, viewSize.height));
	NSRect imageRect = imageBounds;
	if(rotation == 1 || rotation == 3)
	{
		imageRect = rectWithSizeCenteredInRect(NSMakeSize( NSHeight(imageRect), NSWidth(imageRect)),
											   NSMakeRect( 0, 0, NSHeight([self frame]), NSWidth([self frame])));
	}
	firstPageRect.size = scaleSize([firstPageImage size] , NSHeight(imageRect) / [firstPageImage size].height);
	if([secondPageImage isValid])
	{
		secondPageRect.size = scaleSize([secondPageImage size] , NSHeight(imageRect) / [secondPageImage size].height);
		if(sessionController.session.pageOrder)
		{
			firstPageRect.origin = imageRect.origin;
			secondPageRect.origin = NSMakePoint(NSMaxX(firstPageRect), NSMinY(imageRect));
		}
		else
		{
			secondPageRect.origin = imageRect.origin;
			firstPageRect.origin = NSMakePoint(NSMaxX(secondPageRect), NSMinY(imageRect));
		}
	}
	else
	{
		firstPageRect.origin = imageRect.origin;
	}
	
	CGFloat xOrigin = viewSize.width * xpercent;
	CGFloat yOrigin = viewSize.height * ypercent;
	NSPoint recenter = NSMakePoint(xOrigin - visibleRect.size.width / 2, yOrigin - visibleRect.size.height / 2);
	[self scrollPoint: recenter];
	[self setNeedsDisplay: YES];
}


- (NSRect)pageSelectionRect:(NSInteger)selection
{
	NSRect firstPageSide, secondPageSide;
	NSRect bounds = [self bounds];
	if([secondPageImage isValid] == NO)
	{
		firstPageSide = bounds;
		secondPageSide = NSZeroRect;
	}
	else if(sessionController.session.pageOrder)
	{
		firstPageSide = NSMakeRect(0, 0, NSMaxX(firstPageRect), NSHeight(bounds));
		secondPageSide = NSMakeRect(NSMinX(secondPageRect), 0, NSWidth(bounds) - NSMinX(secondPageRect), NSHeight(bounds));
	}
	else
	{
		secondPageSide = NSMakeRect(0, 0, NSMaxX(secondPageRect), NSHeight(bounds));
		firstPageSide = NSMakeRect(NSMinX(firstPageRect), 0, NSWidth(bounds) - NSMinX(firstPageRect), NSHeight(bounds));
	}
	
	if (selection == 1)
	{
		return firstPageSide;
	}
	else if (selection == 2)
	{
		return secondPageSide;
	}
	else
	{
		return NSZeroRect;
	}
}


- (NSRect)imageCropRectangle
{
	if(NSEqualSizes(NSZeroSize, cropRect.size))
	{
		return NSZeroRect;
	}
	
	NSRect selection;
	if (pageSelection == 0)
	{
		selection = NSIntersectionRect(rectFromNegativeRect(cropRect), firstPageRect);
	}
	else
	{
		selection = NSIntersectionRect(rectFromNegativeRect(cropRect), secondPageRect);
	}
	
	NSPoint center = centerPointOfRect(selection);
	NSRect pageRect = NSZeroRect;
	NSSize originalSize = NSZeroSize;
	if(NSPointInRect(center, firstPageRect))
	{
		pageRect = firstPageRect;
		originalSize = [firstPageImage size];
	}
	else if(NSPointInRect(center, secondPageRect))
	{
		pageRect = secondPageRect;
		originalSize = [secondPageImage size];
	}
	
	pageRect.origin = NSMakePoint(selection.origin.x - pageRect.origin.x, selection.origin.y - pageRect.origin.y);
	CGFloat scaling = originalSize.height / pageRect.size.height;
	pageRect = NSMakeRect(pageRect.origin.x * scaling,
						  pageRect.origin.y * scaling,
						  selection.size.width * scaling,
						  selection.size.height * scaling);
	return pageRect;
}


#pragma mark -
#pragma mark Event handling


- (void)scrollWheel:(NSEvent *)theEvent
{
	if ([sessionController pageSelectionInProgress])
	{
		return;
	}
	
	NSEventModifierFlags modifier = [theEvent modifierFlags];
	NSUserDefaults * defaultsController = [NSUserDefaults standardUserDefaults];
	int scaling = [[[sessionController session] valueForKey: TSSTPageScaleOptions] intValue];
	scaling = [sessionController currentPageIsText] ? 2 : scaling;
	
	if((modifier & NSEventModifierFlagCommand) && [theEvent deltaY])
	{
		NSInteger loupeDiameter = [defaultsController integerForKey: TSSTLoupeDiameter];
		loupeDiameter += [theEvent deltaY] > 0 ? -25 : 25;
		loupeDiameter = MAX(loupeDiameter, 200);
		loupeDiameter = MIN(loupeDiameter, 500);
		[defaultsController setInteger: loupeDiameter forKey: TSSTLoupeDiameter];
	}
	else if((modifier & NSEventModifierFlagOption) && [theEvent deltaY])
	{
		CGFloat loupePower = [defaultsController doubleForKey: TSSTLoupePower];
		loupePower += [theEvent deltaY] > 0 ? -0.5 : 0.5;
		loupePower = MAX(loupePower, 1.5);
		loupePower = MIN(loupePower, 6);
		[defaultsController setDouble: loupePower forKey: TSSTLoupePower];
	}
	else if(scaling == 1)
	{
		CGFloat deltaX = [theEvent deltaX];
		if (deltaX != 0.0)
		{
			[theEvent trackSwipeEventWithOptions:NSEventSwipeTrackingLockDirection
						dampenAmountThresholdMin:-1.0
											 max:1.0
									usingHandler:^(CGFloat gestureAmount, NSEventPhase phase, BOOL isComplete, BOOL *stop) {
			}];
		}
		
		
		if (deltaX > 0.0)
		{
			[sessionController pageLeft: self];
		}
		else if (deltaX < 0.0)
		{
			[sessionController pageRight: self];
		}
		
	}
	else
	{
		NSRect visible = [[self enclosingScrollView] documentVisibleRect];
		NSPoint scrollPoint = NSMakePoint(NSMinX(visible) - ([theEvent deltaX] * 5), NSMinY(visible) + ([theEvent deltaY] * 5));
		[self scrollPoint: scrollPoint];
	}
    
    
	if ([defaultsController boolForKey:TSSTEnableSwipe] && theEvent.type == NSEventTypeSwipe)
	{
		CGFloat deltaX = [theEvent deltaX];
		CGFloat deltaY = [theEvent deltaY];
		CGFloat ratio = deltaX / deltaY;
		if isnan(ratio) {ratio = deltaX;}
		if (deltaX != 0.0 && fabs(ratio) >= 1.0)
		{
			[theEvent trackSwipeEventWithOptions:NSEventSwipeTrackingLockDirection
						dampenAmountThresholdMin:-1.0
											 max:1.0
									usingHandler:^(CGFloat gestureAmount, NSEventPhase phase, BOOL isComplete, BOOL *stop) {
				//NSLog(@"gesture amount: %f, phase %04lx, is complete: %@", gestureAmount, (unsigned long)phase, isComplete ? @"YES" : @"NO");
			}];
			
			if (deltaX > 0.0)
			{
				[sessionController pageLeft: self];
			}
			else if (deltaX < 0.0)
			{
				[sessionController pageRight: self];
			}
		}
	}
	
	[sessionController refreshLoupePanel];
}


- (void)keyDown:(NSEvent *)event
{
	if ([sessionController pageSelectionInProgress])
	{
		[sessionController cancelPageSelection];
		pageSelection = -1;
		cropRect = NSZeroRect;
		[self setNeedsDisplay: YES];
		return;
	}
	
	NSEventModifierFlags modifier = [event modifierFlags];
	BOOL shiftKey = modifier & NSEventModifierFlagShift ? YES : NO;
	unichar charNumber = [[event charactersIgnoringModifiers] characterAtIndex: 0];
	NSRect visible = [[self enclosingScrollView] documentVisibleRect];
	NSPoint scrollPoint = visible.origin;
	BOOL scrolling = NO;
	CGFloat delta = shiftKey ? 50 * 3 : 50;
	
	switch (charNumber)
	{
		case NSUpArrowFunctionKey:
			if(![self verticalScrollIsPossible])
			{
				[sessionController previousPage];
			}
			else
			{
				scrollKeys |= TSSTArrowKeyUp;
				scrollPoint.y += delta;
				scrolling = YES;
			}
			break;
		case NSDownArrowFunctionKey:
			if(![self verticalScrollIsPossible])
			{
				[sessionController nextPage];
			}
			else
			{
				scrollKeys |= TSSTArrowKeyDown;
				scrollPoint.y -= delta;
				scrolling = YES;
			}
			break;
		case NSLeftArrowFunctionKey:
			if(![self horizontalScrollIsPossible])
			{
				[sessionController pageLeft: self];
			}
			else
			{
				scrollKeys |= TSSTArrowKeyLeft;
				scrollPoint.x -= delta;
				scrolling = YES;
			}
			break;
		case NSRightArrowFunctionKey:
			if(![self horizontalScrollIsPossible])
			{
				[sessionController pageRight: self];
			}
			else
			{
				scrollKeys |= TSSTArrowKeyRight;
				scrollPoint.x += delta;
				scrolling = YES;
			}
			break;
		case NSPageUpFunctionKey:
			[self pageUp];
			break;
		case NSPageDownFunctionKey:
			[self pageDown];
			break;
		case 0x20:	// Spacebar
			if(shiftKey)
			{
				[self pageUp];
			}
			else
			{
				[self pageDown];
			}
			break;
		case 27:
			[sessionController killTopOptionalUIElement];
			break;
		case 127:
			[self pageUp];
			break;
		default:
			[super keyDown: event];
			break;
	}
	
	if(scrolling && !scrollTimer)
	{
		[self scrollPoint: scrollPoint];
		[sessionController refreshLoupePanel];
		NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										  [NSDate date], @"lastTime", @(shiftKey), @"accelerate",
										  nil, @"leftTurnStart", nil, @"rightTurnStart", nil];
		scrollTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0/10
													   target: self
													 selector: @selector(scroll:)
													 userInfo: userInfo
													  repeats: YES];
	}
}


- (void)pageUp
{
	NSRect visible = [[self enclosingScrollView] documentVisibleRect];
	NSPoint scrollPoint = visible.origin;
	
	if(NSMaxY([self bounds]) <= NSMaxY(visible))
	{
		if(sessionController.session.pageOrder)
		{
			if(NSMinX(visible) > 0)
			{
				scrollPoint = NSMakePoint(NSMinX(visible) - NSWidth(visible), 0);
				[self scrollPoint: scrollPoint];
			}
			else
			{
				[sessionController setPageTurn: 1];
				[sessionController previousPage];
			}
		}
		else
		{
			if(NSMaxX(visible) < NSWidth([self bounds]))
			{
				scrollPoint = NSMakePoint(NSMaxX(visible), 0);
				[self scrollPoint: scrollPoint];
			}
			else
			{
				[sessionController setPageTurn: 2];
				[sessionController previousPage];
			}
		}
	}
	else
	{
		scrollPoint.y += visible.size.height;
		[self scrollPoint: scrollPoint];
	}
}


- (void)pageDown
{
	NSRect visible = [[self enclosingScrollView] documentVisibleRect];
	NSPoint scrollPoint = visible.origin;
	
	if(scrollPoint.y <= 0)
	{
		if(sessionController.session.pageOrder)
		{
			if(NSMaxX(visible) < NSWidth([self bounds]))
			{
				scrollPoint = NSMakePoint(NSMaxX(visible), NSHeight([self bounds]) - NSHeight(visible));
				[self scrollPoint: scrollPoint];
			}
			else
			{
				[sessionController setPageTurn: 2];
				[sessionController nextPage];
			}
		}
		else
		{
			if(NSMinX(visible) > 0)
			{
				scrollPoint = NSMakePoint(NSMinX(visible) - NSWidth(visible), NSHeight([self bounds]) - NSHeight(visible));
				[self scrollPoint: scrollPoint];
			}
			else
			{
				[sessionController setPageTurn: 1];
				[sessionController nextPage];
			}
		}
	}
	else
	{
		scrollPoint.y -= visible.size.height;
		[self scrollPoint: scrollPoint];
	}
}


- (void)keyUp:(NSEvent *)event
{
	unichar charNumber = [[event charactersIgnoringModifiers] characterAtIndex: 0];
	switch (charNumber)
	{
		case NSUpArrowFunctionKey:
			scrollKeys &= ~TSSTArrowKeyUp;
			break;
		case NSDownArrowFunctionKey:
			scrollKeys &= ~TSSTArrowKeyDown;
			break;
		case NSLeftArrowFunctionKey:
			scrollKeys &= ~TSSTArrowKeyLeft;
			break;
		case NSRightArrowFunctionKey:
			scrollKeys &= ~TSSTArrowKeyRight;
			break;
		default:
			break;
	}
}


- (void)flagsChanged:(NSEvent *)theEvent
{
	if([theEvent type] & NSEventTypeKeyDown && [theEvent modifierFlags] & NSEventModifierFlagCommand)
	{
		scrollKeys = 0;
	}
}


- (void)scroll:(NSTimer *)timer
{
	if(!scrollKeys)
	{
		[scrollTimer invalidate];
		scrollTimer = nil;
		// This is to reset the interpolation.
		[self setNeedsDisplay: YES];
		return;
	}
	
	NSTimeInterval delay = 0.2;
	NSRect visible = [[self enclosingScrollView] documentVisibleRect];
	NSDate * currentDate = [NSDate date];
	NSTimeInterval difference = [currentDate timeIntervalSinceDate: [[timer userInfo] valueForKey: @"lastTime"]];
	int multiplier = [[[timer userInfo] valueForKey: @"accelerate"] boolValue] ? 3 : 1;
	[[timer userInfo] setValue: currentDate forKey: @"lastTime"];
	NSPoint scrollPoint = visible.origin;
	int delta = 1000 * difference * multiplier;
	TSSTTurn turn = TSSTTurnNone;
	NSString * directionString = nil;
	BOOL turnDirection = sessionController.session.pageOrder;
	BOOL finishTurn = NO;
	if(scrollKeys & TSSTArrowKeyUp)
	{
		scrollPoint.y += delta;
		if(NSMaxY(visible) >= NSMaxY([self frame]))
		{
			turn = turnDirection ? TSSTTurnLeft : TSSTTurnRight;
		}
	}
	
	if (scrollKeys & TSSTArrowKeyDown)
	{
		scrollPoint.y -= delta;
		if(scrollPoint.y <= 0)
		{
			turn = turnDirection ? TSSTTurnRight : TSSTTurnLeft;
		}
	}
	
	if (scrollKeys & TSSTArrowKeyLeft)
	{
		scrollPoint.x -= delta;
		if(scrollPoint.x <= 0)
		{
			turn = TSSTTurnLeft;
		}
	}
	
	if (scrollKeys & TSSTArrowKeyRight)
	{
		scrollPoint.x += delta;
		if(NSMaxX(visible) >= NSMaxX([self frame]))
		{
			turn = TSSTTurnRight;
		}
	}
	
	if(turn != TSSTTurnNone)
	{
		difference = 0;
		
		if(turn == TSSTTurnRight)
		{
			directionString = @"rightTurnStart";
		}
		else
		{
			directionString = @"leftTurnStart";
		}
		
		if(![[timer userInfo] valueForKey: directionString])
		{
			[[timer userInfo] setValue: currentDate forKey: directionString];
		}
		else
		{
			difference = [currentDate timeIntervalSinceDate: [[timer userInfo] valueForKey: directionString]];
		}
		
		if(difference >= delay)
		{
			if(turn == TSSTTurnLeft)
			{
				[sessionController pageLeft: self];
				finishTurn = YES;
			}
			else if(turn == TSSTTurnRight)
			{
				[sessionController pageRight: self];
				finishTurn = YES;
			}
			
			[scrollTimer invalidate];
			scrollTimer = nil;
		}
	}
	else
	{
		[[timer userInfo] setValue: nil forKey: @"rightTurnStart"];
		[[timer userInfo] setValue: nil forKey: @"leftTurnStart"];
	}
	
	if(!finishTurn)
	{
		NSScrollView * scrollView = [self enclosingScrollView];
		NSClipView * clipView = [scrollView contentView];
		NSRect scrollRect;
		scrollRect.origin = scrollPoint;
		scrollRect.size = NSMakeSize(1, 1);
		scrollRect = [clipView constrainBoundsRect:scrollRect];
		[clipView scrollToPoint: scrollRect.origin];
		[scrollView reflectScrolledClipView: clipView];
	}
	
	[sessionController refreshLoupePanel];
}


- (void)rightMouseDown:(NSEvent *)theEvent
{
	BOOL loupe = !sessionController.session.loupe;
	sessionController.session.loupe = loupe;
}


- (void)mouseDown:(NSEvent *)theEvent
{
	if ([sessionController pageSelectionInProgress])
	{
		NSPoint cursor = [self convertPoint: [theEvent locationInWindow] fromView: nil];
		cropRect.origin = cursor;
	}
	else if([self dragIsPossible])
	{
		[[NSCursor closedHandCursor] set];
	}
}


- (void)mouseMoved:(NSEvent *)theEvent
{
	if ([sessionController pageSelectionInProgress])
	{
		NSPoint cursor = [self convertPoint: [theEvent locationInWindow] fromView: nil];
		if(NSPointInRect(cursor, firstPageRect) && [sessionController canSelectPageIndex: 0])
		{
			pageSelection = 0;
		}
		else if(NSPointInRect(cursor, secondPageRect) && [sessionController canSelectPageIndex: 1])
		{
			pageSelection = 1;
		}
		else
		{
			pageSelection = -1;
		}
		[self setNeedsDisplay: YES];
	}
	else
	{
		[super mouseMoved: theEvent];
	}
}


- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint viewOrigin = [[self enclosingScrollView] documentVisibleRect].origin;
	NSPoint cursor = [theEvent locationInWindow];
	NSPoint currentPoint;
	if ([sessionController pageSelectionInProgress])
	{
		cursor = [self convertPoint: cursor fromView: nil];
		cropRect.size.width = cursor.x - cropRect.origin.x;
		cropRect.size.height = cursor.y - cropRect.origin.y;
		if(NSPointInRect(cropRect.origin, [self pageSelectionRect: 1]))
		{
			pageSelection = 0;
		}
		else if(NSPointInRect(cropRect.origin, [self pageSelectionRect: 2]))
		{
			pageSelection = 1;
		}
		[self setNeedsDisplay: YES];
	}
	else if([self dragIsPossible])
	{
		while ([theEvent type] != NSEventTypeLeftMouseUp)
		{
			if ([theEvent type] == NSEventTypeLeftMouseDragged)
			{
				currentPoint = [theEvent locationInWindow];
				[self scrollPoint: NSMakePoint(viewOrigin.x + cursor.x - currentPoint.x,viewOrigin.y + cursor.y - currentPoint.y)];
				[sessionController refreshLoupePanel];
			}
			theEvent = [[self window] nextEventMatchingMask: NSEventMaskLeftMouseUp | NSEventMaskLeftMouseDragged];
		}
		[[self window] invalidateCursorRectsForView: self];
	}
}


- (void)mouseUp:(NSEvent *)theEvent
{
	if ([sessionController pageSelectionInProgress])
	{
		[sessionController selectedPage: pageSelection withCropRect: [self imageCropRectangle]];
		pageSelection = -1;
		cropRect = NSZeroRect;
		
		[self setNeedsDisplay: YES];
		return;
	}
	
	if([self dragIsPossible])
	{
		[[NSCursor openHandCursor] set];
	}
	
	NSPoint clickPoint = [theEvent locationInWindow];
	int viewSplit = NSWidth([[self enclosingScrollView] frame]) / 2;
	if(NSMouseInRect(clickPoint, [[self enclosingScrollView] frame], [[self enclosingScrollView] isFlipped]))
	{
		if(clickPoint.x < viewSplit)
		{
			if([theEvent modifierFlags] & NSEventModifierFlagOption)
			{
				[NSApp sendAction: @selector(shiftPageLeft:) to: nil from: self];
			}
			else
			{
				[NSApp sendAction: @selector(pageLeft:) to: nil from: self];
			}
		}
		else
		{
			if([theEvent modifierFlags] & NSEventModifierFlagOption)
			{
				[NSApp sendAction: @selector(shiftPageRight:) to: nil from: self];
			}
			else
			{
				[NSApp sendAction: @selector(pageRight:) to: nil from: self];
			}
		}
	}
}

//NOTE: This is for the THREE-finger swipe, not two finger
- (void)swipeWithEvent:(NSEvent *)event
{
	if ([event deltaX] == 1)
	{
		[sessionController pageLeft: self];
	}
	else if ([event deltaX] == -1)
	{
		[sessionController pageRight: self];
	}
}


- (void)rotateWithEvent:(NSEvent *)event
{
	static NSTimeInterval nextValidLeft = -1;
	static NSTimeInterval nextValidRight = -1;
	
	// Prevent more than one rotation in the same direction per second
	if ([event rotation] > 0.5 && [event timestamp] > nextValidRight)
	{
		[sessionController rotateLeft: self];
		nextValidRight = [event timestamp] + 0.75;
	}
	else if ([event rotation] < -0.5 && [event timestamp] > nextValidLeft)
	{
		[sessionController rotateRight: self];
		nextValidLeft = [event timestamp] + 0.75;
	}
}


- (void)magnifyWithEvent:(NSEvent *)event
{
	TSSTManagedSession * session = [sessionController session];
	int scalingOption = [[session valueForKey: TSSTPageScaleOptions] intValue];
	CGFloat previousZoom = [[session valueForKey: TSSTZoomLevel] doubleValue];
	if(scalingOption != 0)
	{
		previousZoom = NSWidth([self imageBounds]) / [self combinedImageSizeForZoom: 1].width;
	}
	
	previousZoom += ([event magnification] * 2);
	previousZoom = previousZoom < 5 ? previousZoom : 5;
	previousZoom = previousZoom > .25 ? previousZoom : .25;
	session.zoomLevel = previousZoom;
	session.scaleOptions = 0;
	
	[self resizeView];
}

- (void)smartMagnifyWithEvent:(NSEvent *)event
{
	//Cycle through the page scaling options
}

- (BOOL)dragIsPossible
{
	return ([self horizontalScrollIsPossible] ||
			([self verticalScrollIsPossible] &&
			 ![sessionController pageSelectionInProgress]));
}


- (BOOL)horizontalScrollIsPossible
{
	NSSize total = imageBounds.size;
	NSSize visible = [[self enclosingScrollView] documentVisibleRect].size;
	return (visible.width < round(total.width));
}


- (BOOL)verticalScrollIsPossible
{
	NSSize total = imageBounds.size;
	NSSize visible = [[self enclosingScrollView] documentVisibleRect].size;
	return (visible.height < round(total.height));
}


- (void)resetCursorRects
{
	if([self dragIsPossible])
	{
		[self addCursorRect: [[self enclosingScrollView] documentVisibleRect] cursor: [NSCursor openHandCursor]];
	}
//	else if(canCrop)
//	{
//		[self addCursorRect: [[self enclosingScrollView] documentVisibleRect] cursor: [NSCursor crosshairCursor]];
//	}
	else
	{
		[super resetCursorRects];
	}
}


@end
