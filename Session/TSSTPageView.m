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
 
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
	OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
	OTHER DEALINGS IN THE SOFTWARE.
	
	Simple Comic
	TSSTPageView.m
*/



#import "TSSTPageView.h"
#import "TSSTImageUtilities.h"
#import "SimpleComicAppDelegate.h"
#import "TSSTSessionWindowController.h"

#define NOTURN 0
#define LEFTTURN 1
#define RIGHTTURN 2
#define UNKTURN 3

@implementation TSSTPageView

@synthesize rotation;
@synthesize dataSource;



- (void)awakeFromNib
{
	/* Doing this so users can drag files into a view. */
    [self registerForDraggedTypes: [NSArray arrayWithObject: NSFilenamesPboardType]];
}



- (id)initWithFrame:(NSRect)aRectangle;
{
	if(self = [super initWithFrame: aRectangle])
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
	}
	return self;
}



- (void) dealloc
{
    id temp;
    [scrollTimer invalidate];
    [scrollTimer release];
    temp = firstPageImage;
    firstPageImage = nil;
	[temp release];
    temp = secondPageImage;
    secondPageImage = nil;
	[temp release];
	[super dealloc];
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
		[firstPageImage release];
		firstPageImage = [first retain];
        [self startAnimationForImage: firstPageImage];
    }
    
	if(second != secondPageImage)
	{
		[secondPageImage release];
		secondPageImage = [second retain];
        [self startAnimationForImage: secondPageImage];
	}

    [self resizeView];
//    [self correctViewPoint]; // Moved to sessionwindow
//	[dataSource setPageTurn: 0];
}



#pragma mark -
#pragma mark Animations


/* Animated GIF method */
- (void)startAnimationForImage:(NSImage *)image
{
    id testImageRep = [image bestRepresentationForDevice: nil];
    int frameCount;
    float frameDuration;
    NSDictionary * animationInfo;
    if([testImageRep class] == [NSBitmapImageRep class])
    {
        frameCount = [[testImageRep valueForProperty: NSImageFrameCount] intValue];
        if(frameCount > 1)
        {
            animationInfo = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: 1], @"imageNumber",
                firstPageImage, @"pageImage",
                [testImageRep valueForProperty: NSImageLoopCount], @"loopCount",nil];
            frameDuration = [[testImageRep valueForProperty: NSImageCurrentFrameDuration] floatValue];
            frameDuration = frameDuration > 0.01 ? frameDuration : 0.01;
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
    NSMutableDictionary * animationInfo = [NSMutableDictionary dictionaryWithDictionary: [timer userInfo]];
    float frameDuration;
    NSImage * pageImage = [[animationInfo valueForKey: @"imageNumber"] intValue] == 1 ? firstPageImage : secondPageImage;
    if([animationInfo valueForKey: @"pageImage"] != pageImage || [self dataSource] == nil)
    {
        return;
    }
    
    NSBitmapImageRep * testImageRep = (NSBitmapImageRep *)[pageImage bestRepresentationForDevice: nil];
    int loopCount = [[animationInfo valueForKey: @"loopCount"] intValue];
    int frameCount = ([[testImageRep valueForProperty: NSImageFrameCount] intValue] - 1);
    int currentFrame = [[testImageRep valueForProperty: NSImageCurrentFrame] intValue];
    
    currentFrame = currentFrame < frameCount ? ++currentFrame : 0;
    if(currentFrame == 0 && loopCount > 1)
    {
        --loopCount;
        [animationInfo setValue: [NSNumber numberWithInt: loopCount] forKey: @"loopCount"];
    }
    
    [testImageRep setProperty: NSImageCurrentFrame withValue: [NSNumber numberWithInt: currentFrame]];
    if(loopCount != 1)
    {
        frameDuration = [[testImageRep valueForProperty: NSImageCurrentFrameDuration] floatValue];
        frameDuration = frameDuration > 0.01 ? frameDuration : 0.01;
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
	if([[pboard types] containsObject: NSFilenamesPboardType])
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
	if([[pboard types] containsObject: NSFilenamesPboardType])
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
	if([[pboard types] containsObject: NSFilenamesPboardType])
	{
		NSArray * filePaths = [pboard propertyListForType: NSFilenamesPboardType];
        [[self dataSource] updateSessionObject];
		[[NSApp delegate] addFiles: filePaths toSession: [[self dataSource] session]];
		return YES;
	}
	return NO;
}



- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard *pboard = [sender draggingPasteboard];
	if([[pboard types] containsObject: NSFilenamesPboardType])
	{
		return YES;
	}
	return NO;
}



#pragma mark -
#pragma mark Drawing



/*! this needs a rewrite bad! Too stinking long. */
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
    
    [firstPageImage drawInRect: [self centerScanRect: firstPageRect]
                      fromRect: NSZeroRect
                     operation: NSCompositeSourceOver 
                      fraction: 1.0];
    
    if([secondPageImage isValid])
    {
        [secondPageImage drawInRect: [self centerScanRect: secondPageRect]
                           fromRect: NSZeroRect
                          operation: NSCompositeSourceOver 
                           fraction: 1.0];
    }

    
	[[NSColor colorWithCalibratedWhite: .2 alpha: 0.5] set];
	NSBezierPath * highlight;
	if(pageSelection != -1 && !NSEqualRects(cropRect, NSZeroRect))
	{
		highlight = [NSBezierPath bezierPathWithRect: cropRect];
		[highlight fill];
		[[NSColor colorWithCalibratedWhite: 1 alpha: 0.8] set];
		[NSBezierPath setDefaultLineWidth: 2];
		[NSBezierPath strokeRect: cropRect];
	}
	else if(pageSelection == 1)
	{
		highlight = [NSBezierPath bezierPathWithRect: firstPageRect];
		[highlight fill];
	}
	else if(pageSelection == 2)
	{
		highlight = [NSBezierPath bezierPathWithRect: secondPageRect];
		[highlight fill];
	}

	[[NSColor colorWithCalibratedWhite: .2 alpha: 0.8] set];

	if((pageSelection == 1 || pageSelection == 2))
	{
		NSDictionary * stringAttributes = [NSDictionary dictionaryWithObjectsAndKeys: 
										   [NSFont fontWithName: @"Lucida Grande" size: 24], NSFontAttributeName, 
										   [NSColor colorWithCalibratedWhite: 1 alpha: 1.0], NSForegroundColorAttributeName,
										   nil];
		NSString * selectionText = [NSString stringWithString: @"Click to select page"];
		NSSize textSize = [selectionText sizeWithAttributes: stringAttributes];
		NSRect bezelRect = rectWithSizeCenteredInRect(textSize, imageBounds);
		NSBezierPath * bezel = roundedRectWithCornerRadius(NSInsetRect(bezelRect, -8, -4), 10);
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



- (void)viewDidEndLiveResize
{
    [self setNeedsDisplay: YES];
    [super viewDidEndLiveResize];
}



/* This method is used to generate the composite loupe image. */
-(NSImage *)imageInRect:(NSRect)rect
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
    
	float power = [[[NSUserDefaults standardUserDefaults] valueForKey: TSSTLoupePower] floatValue];
    float scale;
    float remainder;
    NSRect firstFragment = NSZeroRect;
    NSRect secondFragment = NSZeroRect;
    NSSize zoomSize;

    if([[[[self dataSource] session] valueForKey: TSSTPageOrder] boolValue] || ![secondPageImage isValid])
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
            [firstPageImage drawInRect: NSMakeRect(0,0,NSWidth(rect), NSHeight(rect)) fromRect: firstFragment operation: NSCompositeSourceOver fraction: 1.0];
        }
        
        if(!NSEqualRects(secondFragment, NSZeroRect))
        {
            [secondPageImage drawInRect: NSMakeRect(0,0,NSWidth(rect), NSHeight(rect)) fromRect: secondFragment operation: NSCompositeSourceOver fraction: 1.0];
        }
    [imageFragment unlockFocus];
    return [imageFragment autorelease];
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
    
	if([[self dataSource] pageTurn] == 1)
	{
		correctOrigin.x = (frameSize.width > viewSize.width) ? (frameSize.width - viewSize.width) : 0;
	}
	
	correctOrigin.y = (frameSize.height > viewSize.height) ? (frameSize.height - viewSize.height) : 0;
    
    NSScrollView * scrollView = [self enclosingScrollView];
    NSClipView * clipView = [scrollView contentView];
    [clipView scrollToPoint: correctOrigin];
    [scrollView reflectScrolledClipView: clipView];
}



- (NSSize)combinedImageSizeForZoomLevel:(int)level
{
    float zoomScale = (float)(10.0 + level) / 10.0;
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
    
	return scaleSize(firstSize, zoomScale);
}



- (NSRect)imageBounds
{
    return imageBounds;
}



- (void)resizeView
{
	firstPageRect = NSZeroRect;
	secondPageRect = NSZeroRect;
    NSRect visibleRect = [[self enclosingScrollView] documentVisibleRect];
    NSRect frameRect = [self frame];
    float xpercent = NSMidX(visibleRect) / frameRect.size.width;
    float ypercent = NSMidY(visibleRect) / frameRect.size.height;
    NSSize imageSize = [self combinedImageSizeForZoomLevel: [[[dataSource session] valueForKey: TSSTZoomLevel] intValue]];
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];

    NSSize viewSize;
    float scaleToFit;
	int scaling = [[[[self dataSource] session] valueForKey: TSSTPageScaleOptions] intValue];
	scaling = [[self dataSource] currentPageIsText] ? 2 : scaling;
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
        
        if([[defaults valueForKey: TSSTConstrainScale] boolValue])
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
    
    viewSize = NSMakeSize(roundf(viewSize.width), roundf(viewSize.height));
    [self setFrameSize: viewSize];

    if(![[defaults valueForKey: TSSTConstrainScale] boolValue] && 
	[[[[self dataSource] session] valueForKey: TSSTPageScaleOptions] intValue] != 0 )
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
		if([[[[self dataSource] session] valueForKey: TSSTPageOrder] boolValue])
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
	
    float xOrigin = viewSize.width * xpercent;
    float yOrigin = viewSize.height * ypercent;
    NSPoint recenter = NSMakePoint(xOrigin - visibleRect.size.width / 2, yOrigin - visibleRect.size.height / 2);
    [self scrollPoint: recenter];
    [self setNeedsDisplay: YES];
}


/*  TODO: add some sort of canSelectPage: to TSSTSessionWindowController
	so that non archive pages can be ommitted during icon selection */
- (int)selectPageWithCrop:(BOOL)crop
{
	unsigned int charNumber = 0;
	NSPoint cursorPoint = NSZeroPoint;
	NSPoint currentPoint;
	NSRect dragRect = NSZeroRect;
	NSEvent * theEvent;
	NSRect firstPageSide, secondPageSide = NSZeroRect;
	cropRect = NSZeroRect;
	NSRect bounds = [self bounds];
	
	if(NSEqualRects(secondPageRect, NSZeroRect))
	{
		firstPageSide = [[self enclosingScrollView] documentVisibleRect];
	}
	else if([[[[self dataSource] session] valueForKey: TSSTPageOrder] boolValue])
	{
		firstPageSide = NSMakeRect(0, 0, NSMaxX(firstPageRect), NSHeight(bounds));
		secondPageSide = NSMakeRect(NSMinX(secondPageRect), 0, NSWidth(bounds) - NSMinX(secondPageRect), NSHeight(bounds));
	}
	else
	{
		secondPageSide = NSMakeRect(0, 0, NSMaxX(secondPageRect), NSHeight(bounds));
		firstPageSide = NSMakeRect(NSMinX(firstPageRect), 0, NSWidth(bounds) - NSMinX(firstPageRect), NSHeight(bounds));
	}
	
	cursorPoint = [NSEvent mouseLocation];
    cursorPoint = [self convertPoint: [[self window] convertScreenToBase: cursorPoint] fromView: nil];
	
	do
	{
		if(NSPointInRect(cursorPoint, firstPageSide))
		{
			pageSelection = 1;
		}
		else if(NSPointInRect(cursorPoint, secondPageSide))
		{
			pageSelection = 2;
		}
		else
		{
			pageSelection = 0;
		}
		
		[self setNeedsDisplay: YES];
		
		NSEventType capturedEvents = NSLeftMouseDownMask | NSLeftMouseUpMask | NSMouseMovedMask | NSKeyUpMask;
		if(crop)
		{
			capturedEvents = capturedEvents | NSLeftMouseDraggedMask;
		}
		theEvent = [[self window] nextEventMatchingMask: capturedEvents];
		currentPoint = [self convertPoint: [theEvent locationInWindow] fromView: nil];
		if([theEvent type] == NSKeyUp)
		{
			charNumber = [[theEvent charactersIgnoringModifiers] characterAtIndex: 0];
		}
		else if([theEvent type] == NSLeftMouseDragged)
		{
			dragRect.size.width = currentPoint.x - dragRect.origin.x;
			dragRect.size.height = currentPoint.y - dragRect.origin.y;
			if(NSPointInRect(dragRect.origin, firstPageSide))
			{
				cropRect = NSIntersectionRect(rectFromNegativeRect(dragRect), firstPageRect);
			}
			else if(NSPointInRect(dragRect.origin, secondPageSide))
			{
				cropRect = NSIntersectionRect(rectFromNegativeRect(dragRect), secondPageRect);
			}
		}
		else if([theEvent type] == NSLeftMouseDown)
		{
			dragRect.origin = cursorPoint;
		}
		else if([theEvent type] == NSMouseMoved)
		{
			cursorPoint = currentPoint;
		}
		
	} while ([theEvent type] != NSLeftMouseUp && charNumber != 27);
	int finalSelection = pageSelection && charNumber != 27 ? pageSelection - 1 : -1;
	pageSelection = -1;
	[self setNeedsDisplay: YES];
	
	return finalSelection;
}


- (NSRect)imageCropRectangle
{
	if(NSEqualRects(NSZeroRect, cropRect))
	{
		return NSZeroRect;
	}
	
	NSPoint center = centerPointOfRect(cropRect);
	int pageNumber = 0;
	NSRect pageRect = NSZeroRect;
	NSSize originalSize;
	if(NSPointInRect(center, firstPageRect))
	{
		pageNumber = 1;
		pageRect = firstPageRect;
		originalSize = [firstPageImage size];
	}
	else if(NSPointInRect(center, secondPageRect))
	{
		pageNumber = 2;
		pageRect = secondPageRect;
		originalSize = [secondPageImage size];
	}
	
	pageRect.origin = NSMakePoint(cropRect.origin.x - pageRect.origin.x, cropRect.origin.y - pageRect.origin.y);
	float scaling = originalSize.height / pageRect.size.height;
	pageRect = NSMakeRect(pageRect.origin.x * scaling,
						  pageRect.origin.y * scaling,
						  cropRect.size.width * scaling, 
						  cropRect.size.height * scaling);
	return pageRect;
}


#pragma mark -
#pragma mark Event handling



- (void)scrollWheel:(NSEvent *)theEvent
{
	int modifier = [theEvent modifierFlags];
	NSUserDefaults * defaultsController = [NSUserDefaults standardUserDefaults];
	int scaling = [[[[self dataSource] session] valueForKey: TSSTPageScaleOptions] intValue];
	scaling = [[self dataSource] currentPageIsText] ? 2 : scaling;
	if(modifier & NSAlternateKeyMask && modifier & NSShiftKeyMask)
	{
		if([theEvent deltaY])
		{
			int loupeDiameter = [[defaultsController valueForKey: TSSTLoupeDiameter] intValue];
			loupeDiameter += [theEvent deltaY] > 0 ? 30 : -30;
			loupeDiameter = loupeDiameter < 150 ? 150 : loupeDiameter;
			loupeDiameter = loupeDiameter > 500 ? 500 : loupeDiameter;
			[defaultsController setValue: [NSNumber numberWithInt: loupeDiameter] forKey: TSSTLoupeDiameter];
		}
	}
	else if(modifier & NSAlternateKeyMask)
	{
		if([theEvent deltaX])
		{
			int loupeDiameter = [[defaultsController valueForKey: TSSTLoupeDiameter] intValue];
			loupeDiameter += [theEvent deltaX] > 0 ? 30 : -30;
			loupeDiameter = loupeDiameter < 150 ? 150 : loupeDiameter;
			loupeDiameter = loupeDiameter > 500 ? 500 : loupeDiameter;
			[defaultsController setValue: [NSNumber numberWithInt: loupeDiameter] forKey: TSSTLoupeDiameter];
		}
		
		if([theEvent deltaY])
		{
			int loupePower = [[defaultsController valueForKey: TSSTLoupePower] floatValue];
			loupePower += [theEvent deltaY] > 0 ? 1 : -1;
			loupePower = loupePower < 2 ? 2 : loupePower;
			loupePower = loupePower > 6 ? 6 : loupePower;
			[defaultsController setValue: [NSNumber numberWithFloat: loupePower] forKey: TSSTLoupePower];
		}
	}
	else if(scaling == 1)
	{
		if([theEvent deltaX] > 0)
		{
			scrollwheel.left += [theEvent deltaX];
			scrollwheel.right = 0;
			scrollwheel.up = 0;
			scrollwheel.down = 0;
		}
		else if([theEvent deltaX] < 0)
		{
			scrollwheel.right += [theEvent deltaX];
			scrollwheel.left = 0;
			scrollwheel.up = 0;
			scrollwheel.down = 0;
		}
		else if([theEvent deltaY] > 0)
		{
			scrollwheel.up += [theEvent deltaY];
			scrollwheel.left = 0;
			scrollwheel.right = 0;
			scrollwheel.down = 0;
		}
		else if([theEvent deltaY] < 0)
		{
			scrollwheel.down += [theEvent deltaY];
			scrollwheel.left = 0;
			scrollwheel.right = 0;
			scrollwheel.up = 0;
		}
		
		if(scrollwheel.left > 7)
		{
			[dataSource pageLeft: self];
			scrollwheel.left = 0;
		}
		else if(scrollwheel.right < -7)
		{
			[dataSource pageRight: self];
			scrollwheel.right = 0;
		}
		else if(scrollwheel.up > 20)
		{
			[dataSource previousPage];
		}
		else if(scrollwheel.down < -20)
		{
			[dataSource nextPage];
		}

	}
	else
	{
		NSRect visible = [[self enclosingScrollView] documentVisibleRect];
		NSPoint scrollPoint = NSMakePoint(NSMinX(visible) - ([theEvent deltaX] * 5), NSMinY(visible) + ([theEvent deltaY] * 5));
		[self scrollPoint: scrollPoint];
	}
	
    [[self dataSource] refreshLoupePanel];
}



- (void)keyDown:(NSEvent *)event
{
    int modifier = [event modifierFlags];
    BOOL shiftKey = modifier & NSShiftKeyMask ? YES : NO;
    NSNumber * charNumber = [NSNumber numberWithUnsignedInt: [[event charactersIgnoringModifiers] characterAtIndex: 0]];
    NSRect visible = [[self enclosingScrollView] documentVisibleRect];
    NSPoint scrollPoint = visible.origin;
    BOOL scrolling = NO;
    float delta = shiftKey ? 50 * 3 : 50;
    
	switch ([charNumber unsignedIntValue])
	{
		case NSUpArrowFunctionKey:
			if(![self verticalScrollIsPossible])
			{
				[dataSource previousPage];
			}
			else
			{
				scrollKeys |= 1;
				scrollPoint.y += delta;
				scrolling = YES;
			}
			break;
		case NSDownArrowFunctionKey:
			if(![self verticalScrollIsPossible])
			{
				[dataSource nextPage];
			}
			else
			{
				scrollKeys |= 2;
				scrollPoint.y -= delta;
				scrolling = YES;
			}
			break;
		case NSLeftArrowFunctionKey:
			if(![self horizontalScrollIsPossible])
			{
				[dataSource pageLeft: self];
			}
			else
			{
				scrollKeys |= 4;
				scrollPoint.x -= delta;
				scrolling = YES;
			}
			break;
		case NSRightArrowFunctionKey:
			if(![self horizontalScrollIsPossible])
			{
				[dataSource pageRight: self];
			}
			else
			{
				scrollKeys |= 8;
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
			[[self dataSource] killTopOptionalUIElement];
			break;
		case 127:
			[[self dataSource] removePages: self];
			break;
		default:
			[super keyDown: event];
			break;
	}
	
    if(scrolling && !scrollTimer)
    {
        [self scrollPoint: scrollPoint];
        [[self dataSource] refreshLoupePanel];
        NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
            [NSDate date], @"lastTime", [NSNumber numberWithBool: shiftKey], @"accelerate",
            nil, @"leftTurnStart", nil, @"rightTurnStart", nil];
        scrollTimer = [NSTimer scheduledTimerWithTimeInterval: 1/10
                                                       target: self 
                                                     selector: @selector(scroll:) 
                                                     userInfo: userInfo
                                                      repeats: YES];
        [scrollTimer retain];
    }
}


- (void)pageUp
{
	NSRect visible = [[self enclosingScrollView] documentVisibleRect];
    NSPoint scrollPoint = visible.origin;

	if(NSMaxY([self bounds]) <= NSMaxY(visible))
	{
		if([[[[self dataSource] session] valueForKey: TSSTPageOrder] boolValue])
		{
			if(NSMinX(visible) > 0)
			{
				scrollPoint = NSMakePoint(NSMinX(visible) - NSWidth(visible), 0);
				[self scrollPoint: scrollPoint];
			}
			else
			{
				[dataSource setPageTurn: 1];
				[dataSource previousPage];
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
				[dataSource setPageTurn: 2];
				[dataSource previousPage];
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
		if([[[[self dataSource] session] valueForKey: TSSTPageOrder] boolValue])
		{
			if(NSMaxX(visible) < NSWidth([self bounds]))
			{
				scrollPoint = NSMakePoint(NSMaxX(visible), NSHeight([self bounds]) - NSHeight(visible));
				[self scrollPoint: scrollPoint];
			}
			else 
			{
				[dataSource setPageTurn: 2];
				[dataSource nextPage];
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
				[dataSource setPageTurn: 1];
				[dataSource nextPage];
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
    NSNumber * charNumber = [NSNumber numberWithUnsignedInt: [[event charactersIgnoringModifiers] characterAtIndex: 0]];
    switch ([charNumber unsignedIntValue])
    {
        case NSUpArrowFunctionKey:
            scrollKeys &= 14;
            break;
        case NSDownArrowFunctionKey:
            scrollKeys &= 13;
            break;
        case NSLeftArrowFunctionKey:
            scrollKeys &= 11;
            break;
        case NSRightArrowFunctionKey:
            scrollKeys &= 7;
            break;
        default:
            break;
    }
}



- (void)flagsChanged:(NSEvent *)theEvent
{
    if([theEvent type] & NSKeyDown && [theEvent modifierFlags] & NSCommandKeyMask)
    {
        scrollKeys = 0;
    }
}



- (void)scroll:(NSTimer *)timer
{
    if(!scrollKeys)
    {
        [scrollTimer invalidate];
        [scrollTimer release];
        scrollTimer = nil;
        // This is to reset the interpolation.
        [self setNeedsDisplay: YES];
        return;
    }
    
    BOOL pageTurnAllowed = [[[NSUserDefaults standardUserDefaults] valueForKey: TSSTAutoPageTurn] boolValue];
    NSTimeInterval delay = 0.2;
    NSRect visible = [[self enclosingScrollView] documentVisibleRect];
    NSDate * currentDate = [NSDate date];
    NSTimeInterval difference = [currentDate timeIntervalSinceDate: [[timer userInfo] valueForKey: @"lastTime"]];
    int multiplier = [[[timer userInfo] valueForKey: @"accelerate"] boolValue] ? 3 : 1;
    [[timer userInfo] setValue: currentDate forKey: @"lastTime"];
    NSPoint scrollPoint = visible.origin;
    int delta = 1000 * difference * multiplier;
    int turn = NOTURN;
    NSString * directionString = nil;
    BOOL turnDirection = [[[[self dataSource] session] valueForKey: TSSTPageOrder] boolValue];
    BOOL finishTurn = NO;
    if(scrollKeys & 1)
    {
        scrollPoint.y += delta;
        if(NSMaxY(visible) >= NSMaxY([self frame]) && pageTurnAllowed)
        {
            turn = turnDirection ? LEFTTURN : RIGHTTURN;
        }
    }
    
    if (scrollKeys & 2)
    {
        scrollPoint.y -= delta;
        if(scrollPoint.y <= 0 && pageTurnAllowed)
        {
            turn = turnDirection ? RIGHTTURN : LEFTTURN;
        }
    }
    
    if (scrollKeys & 4)
    {
        scrollPoint.x -= delta;
        if(scrollPoint.x <= 0 && pageTurnAllowed)
        {
            turn = LEFTTURN;
        }
    }
    
    if (scrollKeys & 8)
    {
        scrollPoint.x += delta;
        if(NSMaxX(visible) >= NSMaxX([self frame]) && pageTurnAllowed)
        {
            turn = RIGHTTURN;
        }
    }
    
    if(turn != NOTURN)
    {
        difference = 0;
        
        if(turn == RIGHTTURN)
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
            if(turn == LEFTTURN)
            {
                [dataSource pageLeft: self];
                finishTurn = YES;
            }
            else if(turn == RIGHTTURN)
            {
                [dataSource pageRight: self];
                finishTurn = YES;
            }
            
            [scrollTimer invalidate];
            [scrollTimer release];
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
        [clipView scrollToPoint: [clipView constrainScrollPoint: scrollPoint]];
        [scrollView reflectScrolledClipView: clipView];
    }
    
    [[self dataSource] refreshLoupePanel];
}


- (void)rightMouseDown:(NSEvent *)theEvent
{
	BOOL loupe = [[[dataSource session] valueForKey: @"loupe"] boolValue];
	[[dataSource session] setValue: [NSNumber numberWithBool: !loupe] forKey: @"loupe"];
}


- (void)mouseDown:(NSEvent *)theEvent
{
	if([self dragIsPossible])
    {
        [[NSCursor closedHandCursor] set];
    }
}



- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint viewOrigin = [[self enclosingScrollView] documentVisibleRect].origin;
    NSPoint startPoint = [theEvent locationInWindow];
    NSPoint currentPoint;
    if([self dragIsPossible])
    {
        while ([theEvent type] != NSLeftMouseUp)
        {
            if ([theEvent type] == NSLeftMouseDragged)
            {
                currentPoint = [theEvent locationInWindow];
                [self scrollPoint: NSMakePoint(viewOrigin.x + startPoint.x - currentPoint.x,viewOrigin.y + startPoint.y - currentPoint.y)];
                [[self dataSource] refreshLoupePanel];
            }
            theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
        }
        [[self window] invalidateCursorRectsForView: self];
    }
}



- (void)mouseUp:(NSEvent *)theEvent
{
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
            if([theEvent modifierFlags] & NSAlternateKeyMask)
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
            if([theEvent modifierFlags] & NSAlternateKeyMask)
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



- (BOOL)dragIsPossible
{
//    int scaleToWindow = [[[[self dataSource] session] valueForKey: TSSTPageScaleOptions] intValue];
    NSSize total = imageBounds.size;
    NSSize visible = [[self enclosingScrollView] documentVisibleRect].size;
    
    return (visible.width < total.width || visible.height < total.height);
}


- (BOOL)horizontalScrollIsPossible
{
//	int scaleToWindow = [[[[self dataSource] session] valueForKey: TSSTPageScaleOptions] intValue];
    NSSize total = imageBounds.size;
    NSSize visible = [[self enclosingScrollView] documentVisibleRect].size;
    //scaleToWindow != 1 && 
    return (visible.width < total.width);
}


- (BOOL)verticalScrollIsPossible
{
	NSSize total = imageBounds.size;
    NSSize visible = [[self enclosingScrollView] documentVisibleRect].size;
    return (visible.height < total.height);
}


- (void)resetCursorRects
{   
	
    if([self dragIsPossible])
    {
        [self addCursorRect: [[self enclosingScrollView] documentVisibleRect] cursor: [NSCursor openHandCursor]];
    }
    else
    {
        [super resetCursorRects];
    }
}



@end


