/*	
	Copyright (c) 2006-2009 Dancing Tortoise Software
	Created by Alexander Rauchfuss
 
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
 
    TSSTSessionWindowController.m

*/


#import <Carbon/Carbon.h>
#import <XADMaster/XADArchive.h>
#import "UKXattrMetadataStore.h"
#import "SimpleComicAppDelegate.h"
#import "TSSTSessionWindowController.h"
#import "TSSTPageView.h"
#import "TSSTSortDescriptor.h"
#import "TSSTImageUtilities.h"
#import "TSSTPage.h"
#import "TSSTManagedGroup.h"
#import "TSSTInfoWindow.h"
#import "TSSTThumbnailView.h"
#import "TSSTManagedSession.h"
#import "DTPolishedProgressBar.h"
#import "DTSessionWindow.h"


@implementation TSSTSessionWindowController

@synthesize pageTurn, pageNames, pageSortDescriptor;



/*!
 Turns all of the toolbar images in to templates so that they look consistent with
 othe Apple generated icons.
 */
+ (void)initialize
{
    NSImage * segmentImage = [NSImage imageNamed: @"org_size"];
    [segmentImage setTemplate: YES];
    segmentImage = [NSImage imageNamed: @"fullscreen"];
    [segmentImage setTemplate: YES];
    segmentImage = [NSImage imageNamed: @"Loupe"];
    [segmentImage setTemplate: YES];
    segmentImage = [NSImage imageNamed: @"rotate_l"];
    [segmentImage setTemplate: YES];
    segmentImage = [NSImage imageNamed: @"rotate_r"];
    [segmentImage setTemplate: YES];
    segmentImage = [NSImage imageNamed: @"win_scale"];
    [segmentImage setTemplate: YES];
    segmentImage = [NSImage imageNamed: @"hor_scale"];
    [segmentImage setTemplate: YES];
    segmentImage = [NSImage imageNamed: @"one_page"];
    [segmentImage setTemplate: YES];
    segmentImage = [NSImage imageNamed: @"two_page"];
    [segmentImage setTemplate: YES];
    segmentImage = [NSImage imageNamed: @"rl_order"];
    [segmentImage setTemplate: YES];
    segmentImage = [NSImage imageNamed: @"lr_order"];
    [segmentImage setTemplate: YES];
	segmentImage = [NSImage imageNamed: @"equal"];
    [segmentImage setTemplate: YES];
	segmentImage = [NSImage imageNamed: @"thumbnails"];
    [segmentImage setTemplate: YES];
	segmentImage = [NSImage imageNamed: @"extract"];
    [segmentImage setTemplate: YES];
}



/*!
 
*/
- (id)initWithSession:(TSSTManagedSession *)aSession
{
    self = [super init];
    if (self != nil)
    {
		pageTurn = 0;
		pageSelectionInProgress = None;
		mouseMovedTimer = nil;
//		closing = NO;
        session = [aSession retain];
        BOOL cascade = [session valueForKey: @"position"] ? NO : YES;
        [self setShouldCascadeWindows: cascade];
		/* Make sure that the session does not start out in fullscreen, nor with the loupe enabled. */
		[session setValue: [NSNumber numberWithBool: NO] forKey: TSSTFullscreen];
        [session setValue: [NSNumber numberWithBool: NO] forKey: @"loupe"];
		/* Images are sorted by group and then image name. */
		TSSTSortDescriptor * fileNameSort = [[TSSTSortDescriptor alloc] initWithKey: @"imagePath" ascending: YES];
		TSSTSortDescriptor * archivePathSort = [[TSSTSortDescriptor alloc] initWithKey: @"group.path" ascending: YES];
		self.pageSortDescriptor = [NSArray arrayWithObjects: archivePathSort, fileNameSort, nil];
		[fileNameSort release];
		[archivePathSort release];
    }
	
    return self;
}



- (NSString *)windowNibName
{
    return @"TSSTSessionWindow";
}



/*  Sets up all of the observers and bindings. */
- (void)awakeFromNib
{
    /* This needs to be set as the window subclass that the expose window
        uses has mouse events turned off by default */
    [exposeBezel setIgnoresMouseEvents: NO];
    [exposeBezel setFloatingPanel: YES];
	[exposeBezel setWindowController: self];
    [[self window] setAcceptsMouseMovedEvents: YES];
    [bezelWindow setAcceptsMouseMovedEvents: YES];
    [bezelWindow setFloatingPanel: YES];
	[bezelWindow setNextResponder: [self window]];
    [pageController setSelectionIndex: [[session valueForKey: @"selection"] intValue]];
	
	[fullscreenProgressBar setHighlightColor: nil];
	NSDictionary * fullscreenNumberStyle = [NSDictionary dictionaryWithObjectsAndKeys: 
											 [NSFont fontWithName: @"Lucida Grande" size: 10], NSFontAttributeName,
											 [NSColor colorWithDeviceWhite: 0.82 alpha: 1], NSForegroundColorAttributeName,
											 nil];
	[fullscreenProgressBar setNumberStyle: fullscreenNumberStyle];

    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults addObserver: self forKeyPath: @"constrainScale" options: 0 context: nil];
    [defaults addObserver: self forKeyPath: @"statusBarVisisble" options: 0 context: nil];
    [defaults addObserver: self forKeyPath: @"scrollersVisible" options: 0 context: nil];
    [defaults addObserver: self forKeyPath: @"pageBackgroundColor" options: 0 context: nil];
    [defaults addObserver: self forKeyPath: @"loupeDiameter" options: 0 context: nil];
	[defaults addObserver: self forKeyPath: @"loupePower" options: 0 context: nil];
    [session addObserver: self forKeyPath: TSSTFullscreen options: 0 context: nil];
    [session addObserver: self forKeyPath: TSSTPageOrder options: 0 context: nil];
    [session addObserver: self forKeyPath: TSSTPageScaleOptions options: 0 context: nil];
    [session addObserver: self forKeyPath: TSSTTwoPageSpread options: 0 context: nil];
	[session addObserver: self forKeyPath: @"loupe" options: 0 context: nil];
	
    [session bind: @"selection" toObject: pageController withKeyPath: @"selectionIndex" options: nil];
    
	[pageScrollView setPostsFrameChangedNotifications: YES];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(resizeView) name: NSViewFrameDidChangeNotification object: pageScrollView];
    [pageController addObserver: self forKeyPath: @"selectionIndex" options: 0 context: nil];
    [pageController addObserver: self forKeyPath: @"arrangedObjects.@count" options: 0 context: nil];
    
    [progressBar addObserver: self forKeyPath: @"currentValue" options: 0 context: nil];
    [progressBar bind: @"currentValue" toObject: pageController withKeyPath: @"selectionIndex" options: nil];
    [progressBar bind: @"maxValue" toObject: pageController withKeyPath: @"arrangedObjects.@count" options: nil];
    [progressBar bind: @"leftToRight" toObject: session withKeyPath: TSSTPageOrder options: nil];
	
	[fullscreenProgressBar addObserver: self forKeyPath: @"currentValue" options: 0 context: nil];
    [fullscreenProgressBar bind: @"currentValue" toObject: pageController withKeyPath: @"selectionIndex" options: nil];
    [fullscreenProgressBar bind: @"maxValue" toObject: pageController withKeyPath: @"arrangedObjects.@count" options: nil];
    [fullscreenProgressBar bind: @"leftToRight" toObject: session withKeyPath: TSSTPageOrder options: nil];
    
    [pageView bind: TSSTViewRotation toObject: session withKeyPath: TSSTViewRotation options: nil];
	NSTrackingArea * newArea = [[NSTrackingArea alloc] initWithRect: [progressBar progressRect]
															options: NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow | NSTrackingActiveInActiveApp 
															  owner: self
														   userInfo: [NSDictionary dictionaryWithObject: @"normalProgress" forKey: @"purpose"]];
	[progressBar addTrackingArea: newArea];
	[newArea release];
	newArea = [[NSTrackingArea alloc] initWithRect: [fullscreenProgressBar progressRect]
										   options: NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInActiveApp 
											 owner: self
										  userInfo: [NSDictionary dictionaryWithObject: @"fullScreenProgress" forKey: @"purpose"]];
	[fullscreenProgressBar addTrackingArea: newArea];
	[newArea release];
	[jumpField setDelegate: self];
    [self restoreSession];
}



- (void)dealloc
{
	[(TSSTThumbnailView *)exposeView setDataSource: nil];
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	
    [defaults removeObserver: self forKeyPath: @"statusBarVisisble"];
    [defaults removeObserver: self forKeyPath: @"scrollersVisible"];
	[defaults removeObserver: self forKeyPath: @"pageBackgroundColor"];
    [defaults removeObserver: self forKeyPath: @"constrainScale"];
	[defaults removeObserver: self forKeyPath: @"loupeDiameter"];
	[defaults removeObserver: self forKeyPath: @"loupePower"];
    [pageController removeObserver: self forKeyPath: @"selectionIndex"];
    [pageController removeObserver: self forKeyPath: @"arrangedObjects.@count"];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    [progressBar removeObserver: self forKeyPath: @"currentValue"];
    [progressBar unbind: @"currentValue"];
    [progressBar unbind: @"maxValue"];
    [progressBar unbind: @"leftToRight"];
	
	[fullscreenProgressBar removeObserver: self forKeyPath: @"currentValue"];
    [fullscreenProgressBar unbind: @"currentValue"];
    [fullscreenProgressBar unbind: @"maxValue"];
    [fullscreenProgressBar unbind: @"leftToRight"];
        
    [pageView setSessionController: nil];
	[pageSortDescriptor release];
	[pageNames release];
    [session release];
    [super dealloc];
}



/*  Observes changes to the page controller.  Changes are reflected by the 
    page view.  */
- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object 
						change:(NSDictionary *)change 
					   context:(void *)context
{
    if([[pageController arrangedObjects] count] <= 0)
    {
        [self close];
//		[[NSNotificationCenter defaultCenter] postNotificationName: TSSTSessionEndNotification object: self];
        return;
    }
	
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];

    if([keyPath isEqualToString: TSSTFullscreen])
    {
        [self fullscreen];
    }
    else if([keyPath isEqualToString: TSSTPageScaleOptions] || 
            [keyPath isEqualToString: @"scrollersVisible"])
    {
        [self scaleToWindow];
    }
    else if([keyPath isEqualToString: @"currentValue"])
    {
		if(object == progressBar)
		{
			[pageController setSelectionIndex: [progressBar currentValue]];
		}
		else if(object == fullscreenProgressBar)
		{
			[pageController setSelectionIndex: [fullscreenProgressBar currentValue]];
		}
    }
    else if([keyPath isEqualToString: @"arrangedObjects.@count"])
    {
        [NSThread detachNewThreadSelector: @selector(processThumbs) toTarget: exposeView withObject: nil];
        [self changeViewImages];
    }
    else if([keyPath isEqualToString: TSSTPageOrder])
	{
		[(TSSTThumbnailView *)exposeView setNeedsDisplay: YES];
		[(TSSTThumbnailView *)exposeView buildTrackingRects];
        [self changeViewImages];
	}
	else if([keyPath isEqualToString: @"pageBackgroundColor"])
	{
		NSColor * color = [NSUnarchiver unarchiveObjectWithData: [defaults valueForKey: TSSTBackgroundColor]];
		[pageScrollView setBackgroundColor: color];
	}
    else if([keyPath isEqualToString: @"statusBarVisisble"])
    {
        [self adjustStatusBar];
    }
	else if([keyPath isEqualToString: @"loupeDiameter"])
    {
		int loupeDiameter = [[defaults valueForKey: TSSTLoupeDiameter] intValue];
		[loupeWindow resizeToDiameter: loupeDiameter];
	}
	else if([keyPath isEqualToString: @"loupe"])
    {
		[self refreshLoupePanel];
	}
	else if([keyPath isEqualToString: @"loupePower"])
	{
		[self refreshLoupePanel];
	}
	else 
	{
        [self changeViewImages];
    }
}



#pragma mark -
#pragma mark Progress Bar



- (NSImage *)imageForPageAtIndex:(int)index
{
    return [[[pageController arrangedObjects] objectAtIndex: index] valueForKey: @"thumbnail"];
}



- (NSString *)nameForPageAtIndex:(int)index
{
    return [[[pageController arrangedObjects] objectAtIndex: index] valueForKey: @"name"];
}



#pragma mark -
#pragma mark Event handling



- (void)mouseMoved:(NSEvent *)theEvent
{
	NSRect progressRect;
	NSPoint screenLocation = [[theEvent window] convertBaseToScreen: [theEvent locationInWindow]];
	NSPoint windowLocation = [theEvent locationInWindow];
	if([[session valueForKey: TSSTFullscreen] boolValue])
	{
		if(mouseMovedTimer)
		{
			[mouseMovedTimer invalidate];
			mouseMovedTimer = nil;
		}
		mouseMovedTimer = [NSTimer scheduledTimerWithTimeInterval: 2 target: self  selector: @selector(hideCursor) userInfo: nil repeats: NO];
		
		NSRect bezelFrame = [bezelWindow frame];
		NSRect fullscreenFrame = [[self window] frame];
		BOOL inBezel = NSMouseInRect(screenLocation, bezelFrame, NO);
		if(inBezel && [theEvent window] == bezelWindow)
		{
			progressRect = [fullscreenProgressBar convertRect: [fullscreenProgressBar progressRect] toView: nil];
			if(NSMouseInRect(windowLocation, progressRect, [fullscreenProgressBar isFlipped]))
			{
				[self infoPanelSetupAtPoint: windowLocation];
			}		
		}
		else if(NSMouseInRect(screenLocation, NSMakeRect(0, 0, NSWidth(fullscreenFrame), 4), NO))
		{
			[[self window] addChildWindow: bezelWindow ordered: NSWindowAbove];
			[bezelWindow makeKeyWindow];
			
			windowLocation = [bezelWindow convertScreenToBase: screenLocation];
			progressRect = [fullscreenProgressBar convertRect: [fullscreenProgressBar progressRect] toView: nil];
			if(NSMouseInRect(windowLocation, progressRect, [fullscreenProgressBar isFlipped]))
			{
				[self infoPanelSetupAtPoint: windowLocation];
				[bezelWindow addChildWindow: infoWindow ordered: NSWindowAbove];
			}	
		}
		else
		{
			[[bezelWindow parentWindow] removeChildWindow: bezelWindow];
			[bezelWindow orderOut: self];
		}
	}
	else
	{
		progressRect = [progressBar convertRect: [progressBar progressRect] toView: nil];
		if(NSMouseInRect(windowLocation, progressRect, [progressBar isFlipped]))
		{
			[self infoPanelSetupAtPoint: windowLocation];
		}
	}
	
    [self refreshLoupePanel];
}



- (void)mouseEntered:(NSEvent *)theEvent
{
	NSString * purpose = [(NSDictionary *)[theEvent userData] valueForKey: @"purpose"];
    if([purpose isEqualToString: @"normalProgress"])
    {
        [self infoPanelSetupAtPoint: [theEvent locationInWindow]];
		[[self window] addChildWindow: infoWindow ordered: NSWindowAbove];
    }
	else if([purpose isEqualToString: @"fullScreenProgress"])
	{
		[self infoPanelSetupAtPoint: [theEvent locationInWindow]];
		[bezelWindow addChildWindow: infoWindow ordered: NSWindowAbove];
	}
}



- (void)mouseExited:(NSEvent *)theEvent
{
    if([theEvent trackingArea])
    {
        [[infoWindow parentWindow] removeChildWindow: infoWindow];
        [infoWindow orderOut: self];
    }
}



- (void)refreshLoupePanel
{
    BOOL loupe = [[session valueForKey: @"loupe"] boolValue];
    NSPoint mouse = [NSEvent mouseLocation];
    NSPoint localPoint = [pageView convertPoint: [[self window] convertScreenToBase: mouse] fromView: nil];
	NSPoint scrollPoint = [pageScrollView convertPoint: [[self window] convertScreenToBase: mouse] fromView: nil];
    if(NSMouseInRect(scrollPoint, [pageScrollView bounds], [pageScrollView isFlipped]) 
	   && loupe 
	   && [[self window] isKeyWindow]
	   && pageSelectionInProgress == None)
    {
		NSLog(@"loupe");
		if(![loupeWindow isVisible])
		{
			[[self window] addChildWindow: loupeWindow ordered: NSWindowAbove];
			[NSCursor hide];
		}
		
		NSRect zoomRect = [zoomView frame];
		[loupeWindow centerAtPoint: mouse];
		zoomRect.origin = localPoint;
		[zoomView setImage: [pageView imageInRect: zoomRect]];
    }
    else
	{
		if([loupeWindow isVisible])
        {
            [[loupeWindow parentWindow] removeChildWindow: loupeWindow];
            [loupeWindow orderOut: self];
        }
		
		[NSCursor unhide];
	}
}



- (void)infoPanelSetupAtPoint:(NSPoint)point
{
	NSPoint cursorPoint;
	int index;
	DTPolishedProgressBar * bar;
	if([[session valueForKey: TSSTFullscreen] boolValue])
	{
		bar = fullscreenProgressBar;
		[[infoWindow contentView] setBordered: YES];
		point.y = (NSMaxY([bar frame]) - 11);
	}
	else
	{
		bar = progressBar;
		[[infoWindow contentView] setBordered: NO];
		point.y = (NSMaxY([bar frame]) - 6);
	}
	
	cursorPoint = [bar convertPoint: point fromView: nil];
	index = [bar indexForPoint: cursorPoint];

    NSImage * thumb = [self imageForPageAtIndex: index];
    NSSize thumbSize = sizeConstrainedByDimension([thumb size], 128);
	
    [infoPicture setFrameSize: thumbSize];
    [infoPicture setImage: thumb];
	
    cursorPoint = [[bar window] convertBaseToScreen: point];
	
    [infoWindow caretAtPoint: cursorPoint size: NSMakeSize(thumbSize.width, thumbSize.height) 
			   withLimitLeft: NSMinX([[bar window] frame]) 
					   right: NSMaxX([[bar window] frame])];
}



#pragma mark -
#pragma mark Actions



- (IBAction)changeTwoPage:(id)sender
{
    BOOL spread = [[session valueForKey: TSSTTwoPageSpread] boolValue];
    [session setValue: [NSNumber numberWithBool: !spread] forKey: TSSTTwoPageSpread];
}



- (IBAction)changePageOrder:(id)sender
{
    BOOL pageOrder = [[session valueForKey: TSSTPageOrder] boolValue];
    [session setValue: [NSNumber numberWithBool: !pageOrder] forKey: TSSTPageOrder];
}



- (IBAction)changeFullscreen:(id)sender
{
    BOOL fullscreen = [[session valueForKey: TSSTFullscreen] boolValue];
    [session setValue: [NSNumber numberWithBool: !fullscreen] forKey: TSSTFullscreen];
}



- (IBAction)changeScaling:(id)sender
{
    int scaleType = [sender tag] % 400;
    [session setValue: [NSNumber numberWithInt: scaleType] forKey: TSSTPageScaleOptions];
}


- (IBAction)turnPage:(id)sender
{
    int segmentTag = [[sender cell] tagForSegment: [sender selectedSegment]];
    if(segmentTag == 701)
    {
        [self pageLeft: self];
    }
    else if(segmentTag == 702)
    {
        [self pageRight: self];
    }
}


/*! Method flips the page to the right calling nextPage or previousPage
	depending on the prefered page ordering.
*/
- (IBAction)pageRight:(id)sender
{
    [self setPageTurn: 2];
    if([[session valueForKey: TSSTPageOrder] boolValue])
    {
        [self nextPage];
    }
    else
    {
        [self previousPage];
    }
}



/*! Method flips the page to the left calling nextPage or previousPage
    depending on the prefered page ordering.
*/
- (IBAction)pageLeft:(id)sender
{
    [self setPageTurn: 1];
	
    if([[session valueForKey: TSSTPageOrder] boolValue])
    {
        [self previousPage];
    }
    else
    {
        [self nextPage];
    }
}



- (IBAction)shiftPageRight:(id)sender
{
    if([[session valueForKey: TSSTPageOrder] boolValue])
    {
        [pageController selectNext: sender];
    }
    else
    {
        [pageController selectPrevious: sender];
    }
}



- (IBAction)shiftPageLeft:(id)sender
{
    if([[session valueForKey: TSSTPageOrder] boolValue])
    {
        [pageController selectPrevious: sender];
    }
    else
    {
        [pageController selectNext: sender];
    }
}



- (IBAction)skipRight:(id)sender
{
    int index;
    if([[session valueForKey: TSSTPageOrder] boolValue])
    {
        index = ([pageController selectionIndex] + 10);
        index = index < [[pageController content] count] ? index : [[pageController content] count] - 1;
    }
    else
    {
        index = ([pageController selectionIndex] - 10);
        index = index > 0 ? index : 0;
    }
    
    [pageController setSelectionIndex: index];
}



- (IBAction)skipLeft:(id)sender
{
    int index;
    if(![[session valueForKey: TSSTPageOrder] boolValue])
    {
        index = ([pageController selectionIndex] + 10);
        index = index < [[pageController content] count] ? index : [[pageController content] count] - 1;
    }
    else
    {
        index = ([pageController selectionIndex] - 10);
        index = index > 0 ? index : 0;
    }
    [pageController setSelectionIndex: index];
}



- (IBAction)firstPage:(id)sender
{
    [pageController setSelectionIndex: 0];
}



- (IBAction)lastPage:(id)sender
{
    [pageController setSelectionIndex: [[pageController content] count] - 1];
}



/* Zoom method for the zoom segmented control. Each segment has its own tag. */
- (IBAction)zoom:(id)sender
{
    int segmentTag = [[sender cell] tagForSegment: [sender selectedSegment]];
    if(segmentTag == 801)
    {
        [self zoomIn: self];
    }
    else if(segmentTag == 802)
    {
        [self zoomOut: self];
    }
	else if(segmentTag == 803)
    {
        [self zoomReset: self];
    }
}



- (IBAction)zoomIn:(id)sender
{
    int scalingOption = [[session valueForKey: TSSTPageScaleOptions] intValue];
    float previousZoom = [[session valueForKey: TSSTZoomLevel] floatValue];
    if(scalingOption != 0)
    {
        previousZoom = NSWidth([pageView imageBounds]) / [pageView combinedImageSizeForZoom: 1].width;
    }
	
	previousZoom += 0.1;
    [session setValue: [NSNumber numberWithFloat: previousZoom] forKey: TSSTZoomLevel];
	[session setValue: [NSNumber numberWithInt: 0] forKey: TSSTPageScaleOptions];
	
    [pageView resizeView];
    [self refreshLoupePanel];
}



- (IBAction)zoomOut:(id)sender
{
    int scalingOption = [[session valueForKey: TSSTPageScaleOptions] intValue];
    float previousZoom = [[session valueForKey: TSSTZoomLevel] floatValue];
    if(scalingOption != 0)
    {
        previousZoom = NSWidth([pageView imageBounds]) / [pageView combinedImageSizeForZoom: 1].width;
    }
    
	previousZoom -= 0.1;
	previousZoom = previousZoom < 0.1 ? 0.1 : previousZoom;
    [session setValue: [NSNumber numberWithFloat: previousZoom] forKey: TSSTZoomLevel];
	[session setValue: [NSNumber numberWithInt: 0] forKey: TSSTPageScaleOptions];
	
    [pageView resizeView];
    [self refreshLoupePanel];
}


- (IBAction)zoomReset:(id)sender
{
	[session setValue: [NSNumber numberWithInt: 0] forKey: TSSTPageScaleOptions];
    [session setValue: [NSNumber numberWithFloat: 1.0] forKey: TSSTZoomLevel];
	[pageView resizeView];
    [self refreshLoupePanel];
}



- (IBAction)rotate:(id)sender
{
    int segmentTag = [[sender cell] tagForSegment: [sender selectedSegment]];
    if(segmentTag == 901)
    {
        [self rotateLeft: self];
    }
    else if(segmentTag == 902)
    {
        [self rotateRight: self];
    }
}


- (IBAction)rotateRight:(id)sender
{
    int currentRotation = [[session valueForKey: TSSTViewRotation] intValue];
    currentRotation = currentRotation + 1 > 3 ? 0 : currentRotation + 1;
    [session setValue: [NSNumber numberWithInt: currentRotation] forKey: TSSTViewRotation];
    [self resizeWindow];
    [self refreshLoupePanel];
}



- (IBAction)rotateLeft:(id)sender
{
    int currentRotation = [[session valueForKey: TSSTViewRotation] intValue];
    currentRotation = currentRotation - 1 < 0 ? 3 : currentRotation - 1;
    [session setValue: [NSNumber numberWithInt: currentRotation] forKey: TSSTViewRotation];
    [self resizeWindow];
    [self refreshLoupePanel];
}



- (IBAction)noRotation:(id)sender
{
    [session setValue: [NSNumber numberWithInt: 0] forKey: TSSTViewRotation];
    [self resizeWindow];
    [self refreshLoupePanel];
}



- (IBAction)toggleLoupe:(id)sender
{
    BOOL loupe = [[session valueForKey: @"loupe"] boolValue];
    loupe = !loupe;
    [session setValue: [NSNumber numberWithBool: loupe] forKey: @"loupe"];
}



- (IBAction)togglePageExpose:(id)sender
{
    if([exposeBezel isVisible])
    {
        [[thumbnailPanel parentWindow] removeChildWindow: thumbnailPanel];
        [thumbnailPanel orderOut: self];
        [exposeBezel orderOut: self];
		[[self window] makeKeyAndOrderFront: self];
		[[self window] makeFirstResponder: pageView];
    }
    else
    {
        [NSCursor unhide];
        [(TSSTThumbnailView *)exposeView buildTrackingRects];
        [exposeBezel setFrame: [[[self window] screen] frame] display: NO];
        [exposeBezel makeKeyAndOrderFront: self];
        [NSThread detachNewThreadSelector: @selector(processThumbs) toTarget: exposeView withObject: nil];
    }
}



- (IBAction)launchJumpPanel:(id)sender
{
	[jumpField setIntValue: [pageController selectionIndex] + 1];
	[NSApp beginSheet: jumpPanel modalForWindow: [self window] modalDelegate: self didEndSelector: @selector(closeSheet:) contextInfo: NULL];
}



- (IBAction)cancelJumpPanel:(id)sender
{
	[NSApp endSheet: jumpPanel returnCode: 0];
}



- (IBAction)goToPage:(id)sender
{
    if([jumpField integerValue] != NSNotFound)
    {
        int index = [jumpField intValue] < 1 ? 0 : [jumpField intValue] - 1;
        [pageController setSelectionIndex: index];
    }
	
	[NSApp endSheet: jumpPanel returnCode: 1];
}



- (IBAction)removePages:(id)sender
{
	pageSelectionInProgress = Delete;
	[self changeViewForSelection];
}


/*  Method that allows the user to select an icon for comic archives.
	Calls pageView and verifies that the images selected are from an
	archive. */
- (IBAction)setArchiveIcon:(id)sender
{
	pageSelectionInProgress = Icon;
	[self changeViewForSelection];
}



/*	Saves the selected page to a user specified location. */
- (IBAction)extractPage:(id)sender
{
	pageSelectionInProgress = Extract;
	[self changeViewForSelection];
}



- (BOOL)pageSelectionCanCrop
{
	return (pageSelectionInProgress == Icon);
}


/* Used by all of the page selection methods to make both pages visible.  Also adds a small
	gutter around the images for cropping. */
- (void)changeViewForSelection
{
	savedZoom = [[session valueForKey: TSSTZoomLevel] floatValue];
	[pageScrollView setHasVerticalScroller: NO];
    [pageScrollView setHasHorizontalScroller: NO];
	[self refreshLoupePanel];
	NSSize imageSize = [pageView combinedImageSizeForZoom: 1];
	NSSize scrollerBounds = [[pageView enclosingScrollView] bounds].size;
	scrollerBounds.height -= 20;
	scrollerBounds.width -= 20;
	float factor;
	if(imageSize.width / imageSize.height > scrollerBounds.width / scrollerBounds.height)
	{
		factor = scrollerBounds.width / imageSize.width;
	}
	else
	{		
		factor = scrollerBounds.height / imageSize.height;
	}
	
	[session setValue: [NSNumber numberWithFloat: factor] forKey: TSSTZoomLevel];
	[pageView resizeView];
}



- (BOOL)canSelectPageIndex:(NSInteger)selection
{
	int index = [pageController selectionIndex];
	index += selection;
	TSSTPage * selectedPage = [[pageController arrangedObjects] objectAtIndex: index];
	TSSTManagedGroup * selectedGroup = [selectedPage valueForKey: @"group"];
	/* Makes sure that the group is both an archive and not nested */
	if([selectedGroup class] == [TSSTManagedArchive class] && 
	   selectedGroup == [selectedGroup topLevelGroup] &&
	   ![[selectedPage valueForKey: @"text"] boolValue])
	{
		return YES;
	}
	
	return NO;
}



- (BOOL)pageSelectionInProgress
{
	return (pageSelectionInProgress != None);
}



- (void)cancelPageSelection
{
	[session setValue: [NSNumber numberWithFloat: savedZoom] forKey: TSSTZoomLevel];
	pageSelectionInProgress = None;
	[self scaleToWindow];
}



- (void)selectedPage:(NSInteger)selection withCropRect:(NSRect)cropRect
{
	switch (pageSelectionInProgress)
	{
		case Icon:
			[self setIconWithSelection: selection andCropRect: cropRect];
			break;
		case Delete:
			[self deletePageWithSelection: selection];
			break;
		case Extract:
			[self extractPageWithSelection: selection];
			break;
		default:
			break;
	}
	
	[session setValue: [NSNumber numberWithFloat: savedZoom] forKey: TSSTZoomLevel];
	pageSelectionInProgress = None;
	[self scaleToWindow];
}



- (void)deletePageWithSelection:(NSInteger)selection
{
	if(selection != -1)
	{
		int index = [pageController selectionIndex];
		index += selection;
		TSSTPage * selectedPage = [[pageController arrangedObjects] objectAtIndex: index];
		[pageController removeObject: selectedPage];
		[[self managedObjectContext] deleteObject: selectedPage];
	}
}



- (void)extractPageWithSelection:(NSInteger)selection
{
	/*	selectpage returns prompts the user for which page they wish to use.
	 If there is only one page or the user selects the first page 0 is returned,
	 otherwise 1. */
	if(selection != -1)
	{
		int index = [pageController selectionIndex];
		index += (selection - 1);
		TSSTPage * selectedPage = [[pageController arrangedObjects] objectAtIndex: index];
		
		NSSavePanel * savePanel = [NSSavePanel savePanel];
		[savePanel setTitle: @"Extract Page"];
		[savePanel setPrompt: @"Extract"];
		if(NSOKButton == [savePanel runModalForDirectory: nil file: [selectedPage name]])
		{
			[[selectedPage pageData] writeToFile: [savePanel filename] atomically: YES];
		}
	}
}



- (void)setIconWithSelection:(NSInteger)selection andCropRect:(NSRect)cropRect
{
	if(selection != -1)
	{
		int index = [pageController selectionIndex];
		index += selection;
		TSSTPage * selectedPage = [[pageController arrangedObjects] objectAtIndex: index];
		TSSTManagedGroup * selectedGroup = [selectedPage valueForKey: @"group"];
		/* Makes sure that the group is both an archive and not nested */
		if([selectedGroup class] == [TSSTManagedArchive class] && 
		   selectedGroup == [selectedGroup topLevelGroup] &&
		   ![[selectedPage valueForKey: @"text"] boolValue])
		{
			NSString * archivePath = [[selectedGroup valueForKey: @"path"] stringByStandardizingPath];
			if([(TSSTManagedArchive *)selectedGroup quicklookCompatible])
			{
				int coverIndex = [[selectedPage valueForKey: @"index"] intValue];
				XADString * coverName = [(XADArchive *)[selectedGroup instance] rawNameOfEntry: coverIndex];
				[UKXattrMetadataStore setString: [coverName stringWithEncoding: NSNonLossyASCIIStringEncoding]
										 forKey: @"QCCoverName" 
										 atPath: archivePath 
								   traverseLink: NO];
				[UKXattrMetadataStore setString: NSStringFromRect(cropRect)
										 forKey: @"QCCoverRect" 
										 atPath: archivePath 
								   traverseLink: NO];
				
				[NSTask launchedTaskWithLaunchPath: @"/usr/bin/touch" 
										 arguments: [NSArray arrayWithObject: archivePath]];
			}
			else
			{
				NSRect drawRect = NSMakeRect(0, 0, 496, 496);
				NSImage * iconImage = [[NSImage alloc] initWithSize: drawRect.size];
				cropRect.size = NSEqualSizes(cropRect.size, NSZeroSize) ? NSMakeSize([[selectedPage valueForKey: @"width"] floatValue], [[selectedPage valueForKey: @"height"] floatValue]) : cropRect.size;
				drawRect = rectWithSizeCenteredInRect( cropRect.size, drawRect);
				
				[iconImage lockFocus];
				[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
				[[selectedPage pageImage] drawInRect: drawRect fromRect: cropRect operation: NSCompositeSourceOver fraction: 1];
				[iconImage unlockFocus];
				
				NSImage * shadowImage = [[NSImage alloc] initWithSize: NSMakeSize(512, 512)];
				
				NSShadow * thumbShadow = [NSShadow new];
				[thumbShadow setShadowOffset: NSMakeSize(0.0, -8.0)];
				[thumbShadow setShadowBlurRadius: 25.0];
				[thumbShadow setShadowColor: [NSColor colorWithCalibratedWhite: 0.2 alpha: 1.0]];				
				
				[shadowImage lockFocus];
				[thumbShadow set];
				[iconImage drawInRect: NSMakeRect(16, 16, 496, 496) fromRect: NSZeroRect operation: NSCompositeSourceOver fraction: 1];
				[shadowImage unlockFocus];
				
				[[NSWorkspace sharedWorkspace] setIcon: shadowImage forFile: archivePath options: 0];
				
				[thumbShadow release];
				[iconImage release];
				[shadowImage release];
			}
		}
	}
	[session setValue: [NSNumber numberWithFloat: savedZoom] forKey: TSSTZoomLevel];
}



- (void)closeSheet:(int)code
{
	[jumpPanel close];
}


#pragma mark -
#pragma mark Convenience Methods



- (void)hideCursor
{
	mouseMovedTimer = nil;

	if([[session valueForKey: TSSTFullscreen] boolValue])
	{
		[NSCursor setHiddenUntilMouseMoves: YES];
	}
}



/*  When a session is launched this method is called.  It checks to see if the 
    session was a saved session or one that is brand new.  If it was a saved 
    session then all of the saved session information is passed to the window
    and view. */
- (void)restoreSession
{
    [self changeViewImages];
    [self scaleToWindow];
	[self adjustStatusBar];
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    int loupeDiameter = [[defaults valueForKey: TSSTLoupeDiameter] intValue];
    [loupeWindow setFrame:NSMakeRect(0,0, loupeDiameter, loupeDiameter) display: NO];
    NSColor * color = [NSUnarchiver unarchiveObjectWithData: [defaults valueForKey: TSSTBackgroundColor]];
	[pageScrollView setBackgroundColor: color];
    [pageView setRotation: [[session valueForKey: TSSTViewRotation] intValue]];
    NSValue * positionValue;
    NSData * posData = [session valueForKey: @"position"];
	
    if(posData)
    {
        positionValue = [NSUnarchiver unarchiveObjectWithData: posData];
        [[self window] setFrame: [positionValue rectValue] display: NO];
    }
	
    posData = [session valueForKey: TSSTScrollPosition];
    if(posData)
    {
		[self setShouldCascadeWindows: NO];
        positionValue = [NSUnarchiver unarchiveObjectWithData: posData];
        [pageView scrollPoint: [positionValue pointValue]];
    }
    else
    {
		[self setShouldCascadeWindows: YES];
        if(![[defaults valueForKey: TSSTWindowAutoResize] boolValue])
        {
            [[self window] zoom: self];
        }
        [pageView correctViewPoint];
    }
}



/*  This method figures out which pages should be displayed in the view.  
    To do so it looks at which page is currently selected as well as its aspect ratio
    and that of the next image */
- (void)changeViewImages
{
    int count = [[pageController arrangedObjects] count];
    int index = [pageController selectionIndex];
    TSSTPage * pageOne = [[pageController arrangedObjects] objectAtIndex: index];
    TSSTPage * pageTwo = (index + 1) < count ? [[pageController arrangedObjects] objectAtIndex: (index + 1)] : nil;
    NSString * titleString = [pageOne valueForKey: @"name"];
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	NSString * representationPath;
	
    BOOL currentAllowed = ![pageOne shouldDisplayAlone] && 
        !(index == 0 && [[defaults valueForKey: TSSTLonelyFirstPage] boolValue]);
    
    if(currentAllowed && [[session valueForKey: TSSTTwoPageSpread] boolValue] && pageTwo && ![pageTwo shouldDisplayAlone])
    {
        if([[session valueForKey: TSSTPageOrder] boolValue])
        {
            titleString = [NSString stringWithFormat:@"%@ %@", titleString, [pageTwo valueForKey: @"name"]];
        }
        else
        {
            titleString = [NSString stringWithFormat:@"%@ %@", [pageTwo valueForKey: @"name"], titleString];
        }
    }
    else
    {
        pageTwo = nil;
    }
	
	representationPath = [pageOne valueForKey: @"group"] ? [pageOne valueForKeyPath: @"group.topLevelGroup.path"] : [pageOne valueForKeyPath: @"imagePath"];
	[[self window] setRepresentedFilename: representationPath];

    [self setValue: titleString forKey: @"pageNames"];
    [pageView setFirstPage: [pageOne valueForKey: @"pageImage"] secondPageImage: [pageTwo valueForKey: @"pageImage"]];
    
    [self scaleToWindow];
	[pageView correctViewPoint];
    [self refreshLoupePanel];
}



- (void)resizeWindow
{
    if(![[session valueForKey: TSSTFullscreen] boolValue] &&
       [[[NSUserDefaults standardUserDefaults] valueForKey: TSSTWindowAutoResize] boolValue])
    {
        NSRect allowedRect = [[[self window] screen] visibleFrame];
        NSRect zoomFrame = [self optimalPageViewRectForRect: allowedRect];
        [[self window] setFrame: zoomFrame display: YES animate: NO];
    }
}



- (void)fullscreen
{
    if(mouseMovedTimer)
	{
		[mouseMovedTimer invalidate];
		mouseMovedTimer = nil;
	}
	NSValue * rectangleValue;
	NSData * rectData;
	NSRect windowRect;
    if([[session valueForKey: TSSTFullscreen] boolValue])
    {
        rectangleValue = [NSValue valueWithRect: [[self window] frame]];
        rectData = [NSArchiver archivedDataWithRootObject: rectangleValue];
        [session setValue: rectData forKey: @"position" ];
        SetSystemUIMode(kUIModeAllHidden, kUIOptionAutoShowMenuBar);
		windowRect = [[[self window] screen] frame];
		windowRect.size.height += [(DTSessionWindow *)[self window] toolbarHeight];
		[(DTSessionWindow *)[self window] setFullscreen: YES];
		[[self window] setFrame: windowRect display: NO animate: NO];
		[[self window] setShowsResizeIndicator: NO];
		[self adjustStatusBar];
		mouseMovedTimer = [NSTimer scheduledTimerWithTimeInterval: 2 target: self  selector: @selector(hideCursor) userInfo: nil repeats: NO];
    }
    else
    {
        SetSystemUIMode(kUIModeNormal, 0);
		[[bezelWindow parentWindow] removeChildWindow: bezelWindow];
		[bezelWindow orderOut: self];
		[(DTSessionWindow *)[self window] setFullscreen: NO];
		rectData = [session valueForKey: @"position" ];
		rectangleValue = [NSUnarchiver unarchiveObjectWithData: rectData];
		windowRect = [rectangleValue rectValue];
		[[self window] setShowsResizeIndicator: YES];
		[[self window] setFrame: windowRect display: NO animate: NO];
        [self adjustStatusBar];
    }
	
	[[infoWindow parentWindow] removeChildWindow: infoWindow];
	[infoWindow orderOut: self];
	
    [[loupeWindow parentWindow] removeChildWindow: loupeWindow];
    [loupeWindow orderOut: self];
}



- (void)scaleToWindow
{
    BOOL hasVert = NO;
    BOOL hasHor = NO;
	int scaling = [[session valueForKey: TSSTPageScaleOptions] intValue];
	
	if(pageSelectionInProgress || ![[[NSUserDefaults standardUserDefaults] valueForKey: TSSTScrollersVisible] boolValue])
	{
		scaling = 1;
	}
	else if([self currentPageIsText])
	{
		scaling = 2;
	}

	switch (scaling)
	{
	case  0:
		hasVert = YES;
		hasHor = YES;
		break;
	case  2:
		[session setValue: [NSNumber numberWithFloat: 1] forKey: TSSTZoomLevel];
		if([pageView rotation] == 1 || [pageView rotation] == 3)
		{
			hasHor = YES;
		}
		else
		{
			hasVert = YES;
		}
		break;
	default:	
		[session setValue: [NSNumber numberWithFloat: 1] forKey: TSSTZoomLevel];
		break;
	}
    
    [pageScrollView setHasVerticalScroller: hasVert];
    [pageScrollView setHasHorizontalScroller: hasHor];
	
	if(pageSelectionInProgress == None)
	{
		[self resizeWindow];
	}
	
    [pageView resizeView];
    [self refreshLoupePanel];
}



- (void)adjustStatusBar
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSRect scrollViewRect;
    BOOL statusBar = [[defaults valueForKey: TSSTStatusbarVisible] boolValue] && ![[session valueForKey: TSSTFullscreen] boolValue];
    if(statusBar)
    {
        scrollViewRect = [[[self window] contentView] frame];
        scrollViewRect = NSMakeRect(NSMinX(scrollViewRect), 
                                    NSMinY(scrollViewRect) + 23,
                                    NSWidth(scrollViewRect),
                                    NSHeight(scrollViewRect) - 23);
        [[self window] setContentBorderThickness: 23 forEdge: NSMinYEdge];
        [pageScrollView setFrame: scrollViewRect];
        [progressBar setHidden: NO];
        [self resizeWindow];
    }
    else
    {
        scrollViewRect = [[[self window] contentView] frame];
        [progressBar setHidden: YES];
        [pageScrollView setFrame: scrollViewRect];
        [[self window] setContentBorderThickness: 0 forEdge: NSMinYEdge];
        [self resizeWindow];
    }
}



/*! Selects the next non visible page.  Logic looks figures out which 
images are currently visible and then skips over them.
*/
- (void)nextPage
{
    if(![[session valueForKey: TSSTTwoPageSpread] boolValue])
    {
        [pageController selectNext: self];
        return;
    }
    
    int numberOfImages = [[pageController arrangedObjects] count];
	int selectionIndex = [pageController selectionIndex];
	if((selectionIndex + 1) >= numberOfImages)
	{
		return;
	}
    
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	BOOL current = ![[[pageController arrangedObjects] objectAtIndex: selectionIndex] shouldDisplayAlone] &&
        !(selectionIndex == 0 &&[[defaults valueForKey: TSSTLonelyFirstPage] boolValue]);
	BOOL next = ![[[pageController arrangedObjects] objectAtIndex: (selectionIndex + 1)] shouldDisplayAlone];
	
	if((!current || !next) && ((selectionIndex + 1) < numberOfImages))
	{
		[pageController setSelectionIndex: (selectionIndex + 1)];
	}
	else if((selectionIndex + 2) < numberOfImages)
	{
		[pageController setSelectionIndex: (selectionIndex + 2)];
	}
	else if(((selectionIndex + 1) < numberOfImages) && !next)
	{
		[pageController setSelectionIndex: (selectionIndex + 1)];
	}
}



/*! Selects the previous non visible page.  Logic looks figures out which 
images are currently visible and then skips over them.
*/
- (void)previousPage
{
    if(![[session valueForKey: TSSTTwoPageSpread] boolValue])
    {
        [pageController selectPrevious: self];
        return;
    }
    
	int selectionIndex = [pageController selectionIndex];
	if((selectionIndex - 2) >= 0)
	{
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];

        BOOL previousPage = ![[[pageController arrangedObjects] objectAtIndex: (selectionIndex - 1)] shouldDisplayAlone];
		BOOL pageBeforeLast = ![[[pageController arrangedObjects] objectAtIndex: (selectionIndex - 2)] shouldDisplayAlone] && 
            !((selectionIndex - 2) == 0 && [[defaults valueForKey: TSSTLonelyFirstPage] boolValue]);	
        
        if(!previousPage || !pageBeforeLast)
		{
			[pageController setSelectionIndex: (selectionIndex - 1)];
			return;
		}
		[pageController setSelectionIndex: (selectionIndex - 2)];
		return;
	}
	
	if((selectionIndex - 1) >= 0)
	{
		[pageController setSelectionIndex: (selectionIndex - 1)];
	}
}


/*! This method is called in preparation for saving. */
- (void)updateSessionObject
{
    if(![[session valueForKey: TSSTFullscreen] boolValue])
    {
        NSValue * postionValue = [NSValue valueWithRect: [[self window] frame]];
        NSData * posData = [NSArchiver archivedDataWithRootObject: postionValue];
        [session setValue: posData forKey: @"position" ];
        
        postionValue = [NSValue valueWithPoint: [[pageView enclosingScrollView] documentVisibleRect].origin];
        posData = [NSArchiver archivedDataWithRootObject: postionValue];
        [session setValue: posData forKey: TSSTScrollPosition ];
    }
    else
    {
        [session setValue: nil forKey: TSSTScrollPosition ];
    }
}


- (void)killTopOptionalUIElement
{
	if([exposeBezel isVisible])
	{
		[exposeBezel removeChildWindow: thumbnailPanel];
        [thumbnailPanel orderOut: self];
		[exposeBezel orderOut: self];
	}
	else if([[session valueForKey: @"loupe"] boolValue])
	{
		[session setValue: [NSNumber numberWithBool: NO] forKey: @"loupe"];
	}
	else if([[session valueForKey: TSSTFullscreen] boolValue])
	{
		[session setValue: [NSNumber numberWithBool: NO] forKey: TSSTFullscreen];
	}
}


- (void)killAllOptionalUIElements
{
    [session setValue: [NSNumber numberWithBool: NO] forKey: TSSTFullscreen];
    [session setValue: [NSNumber numberWithBool: NO] forKey: @"loupe"];
    [self refreshLoupePanel];
	[exposeBezel removeChildWindow: thumbnailPanel];
	[thumbnailPanel orderOut: self];
	[exposeBezel orderOut: self];
}


#pragma mark -
#pragma mark Binding Methods



- (TSSTManagedSession *)session
{
    return session;
}



- (NSManagedObjectContext *)managedObjectContext
{
    return [[NSApp delegate] managedObjectContext];
}


- (BOOL)canTurnPageLeft
{
	if([[session valueForKey: TSSTPageOrder] boolValue])
    {
        return [self canTurnPreviousPage];
    }
    else
    {
        return [self canTurnPageNext];
    }
}


- (BOOL)canTurnPageRight
{
	if([[session valueForKey: TSSTPageOrder] boolValue])
    {
        return [self canTurnPageNext];
    }
    else
    {
        return [self canTurnPreviousPage];
    }
}


/*	TODO: make the following a bit smarter.  Also the next/previous page turn logic
	ie. Should not be able to turn the page if 2 pages from the end */
- (BOOL)canTurnPreviousPage
{
	return !([pageController selectionIndex] <= 0);
}


- (BOOL)canTurnPageNext
{
	int selectionIndex = [pageController selectionIndex];
	if([pageController selectionIndex] >= ([[pageController content] count] - 1))
	{
		return NO;
	}
	
	if((selectionIndex + 1) == ([[pageController content] count] - 1) && [[session valueForKey: TSSTTwoPageSpread] boolValue])
	{
		NSArray * arrangedPages = [pageController arrangedObjects];
		BOOL displayCurrentAlone = [[arrangedPages objectAtIndex: selectionIndex] shouldDisplayAlone];
		BOOL displayNextAlone = [[arrangedPages objectAtIndex: selectionIndex + 1] shouldDisplayAlone];

		if (!displayCurrentAlone && !displayNextAlone) {
			return NO;
		}
	}
	
	return YES;	
}


#pragma mark Menus


- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if(pageSelectionInProgress)
	{
		return NO;
	}
	
	BOOL valid = YES;
    int state;
    if([menuItem action] == @selector(changeFullscreen:))
    {
        state = [[session valueForKey: TSSTFullscreen] boolValue] ? NSOnState : NSOffState;
        [menuItem setState: state];
    }
    else if([menuItem action] == @selector(changeTwoPage:))
    {
        state = [[session valueForKey: TSSTTwoPageSpread] boolValue] ? NSOnState : NSOffState;
        [menuItem setState: state];
    }
    else if([menuItem action] == @selector(changePageOrder:))
    {
        if([[session valueForKey: TSSTPageOrder] boolValue])
        {
            [menuItem setTitle: NSLocalizedString(@"Right To Left", @"Right to left page order menu item text")];
        }
        else
        {
            [menuItem setTitle: NSLocalizedString(@"Left To Right", @"Left to right page order menu item text")];
        }
    }
	else if([menuItem action] == @selector(pageRight:))
	{
		valid = [self canTurnPageRight];
	}
	else if([menuItem action] == @selector(pageLeft:))
	{
		valid = [self canTurnPageLeft];
	}
	else if ([menuItem action] == @selector(firstPage:))
	{
		valid = !([pageController selectionIndex] <= 0);
	}
	else if ([menuItem action] == @selector(lastPage:))
	{
		valid = !([pageController selectionIndex] >= ([[pageController content] count] - 1));
	}
	else if ([menuItem action] == @selector(shiftPageRight:))
	{
		valid = [self canTurnPageRight];
	}
	else if ([menuItem action] == @selector(shiftPageLeft:))
	{
		valid = [self canTurnPageLeft];
	}
	else if ([menuItem action] == @selector(skipRight:))
	{
		valid = [self canTurnPageRight];
	}
	else if ([menuItem action] == @selector(skipLeft:))
	{
		valid = [self canTurnPageLeft];
	}
	else if ([menuItem action] == @selector(setArchiveIcon:))
	{
		valid = ![[session valueForKey: TSSTViewRotation] intValue];
	}
	else if ([menuItem action] == @selector(extractPage:))
	{
		valid = ![[session valueForKey: TSSTViewRotation] intValue];
	}
	else if ([menuItem action] == @selector(removePages:))
	{
		valid = ![[session valueForKey: TSSTViewRotation] intValue];
	}
    else if([menuItem tag] == 400)
    {
        state = [[session valueForKey: TSSTPageScaleOptions] intValue] == 0 ? NSOnState : NSOffState;
        [menuItem setState: state];
    }
    else if([menuItem tag] == 401)
    {
        state = [[session valueForKey: TSSTPageScaleOptions] intValue] == 1 ? NSOnState : NSOffState;
        [menuItem setState: state];
    }
    else if([menuItem tag] == 402)
    {
        state = [[session valueForKey: TSSTPageScaleOptions] intValue] == 2 ? NSOnState : NSOffState;
        [menuItem setState: state];
    }
	
    return valid;
}


#pragma mark -
#pragma mark Delegates


- (BOOL)control:(NSTextField *)control didFailToFormatString:(NSString *)string errorDescription:(NSString *)error
{
	int pageNumber = [string intValue];
	if(pageNumber > [[pageController arrangedObjects] count])
	{
		[jumpField setIntValue: [[pageController arrangedObjects] count]];
	}
	else
	{
		NSBeep();
		[jumpField setIntValue: [pageController selectionIndex] + 1];
	}
	
	return YES;
}



- (void)prepareToEnd
{
	[[self window] setAcceptsMouseMovedEvents: NO];
	[mouseMovedTimer invalidate];
	mouseMovedTimer = nil;
    [NSCursor unhide];
    SetSystemUIMode(kUIModeNormal, 0);
	
	[session removeObserver: self forKeyPath: TSSTFullscreen];
    [session removeObserver: self forKeyPath: TSSTPageOrder];
    [session removeObserver: self forKeyPath: TSSTPageScaleOptions];
    [session removeObserver: self forKeyPath: TSSTTwoPageSpread];
	[session removeObserver: self forKeyPath: @"loupe"];
    [session unbind: TSSTViewRotation];
    [session unbind: @"selection"];
}




- (BOOL)windowShouldClose:(id)sender
{
	[self prepareToEnd];
	[[NSNotificationCenter defaultCenter] postNotificationName: TSSTSessionEndNotification object: self];

    return YES;
}



- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
    if([aNotification object] == [self window] && [[session valueForKey: TSSTFullscreen] boolValue])
    {
        SetSystemUIMode(kUIModeAllHidden, kUIOptionAutoShowMenuBar);
        [pageView setNeedsDisplay: YES];
		if([[session valueForKey: @"loupe"] boolValue])
		{
			[NSCursor hide];
		}
		
		if(mouseMovedTimer)
		{
			[mouseMovedTimer invalidate];
			mouseMovedTimer = nil;
		}
		mouseMovedTimer = [NSTimer scheduledTimerWithTimeInterval: 2 target: self  selector: @selector(hideCursor) userInfo: nil repeats: NO];
		[self refreshLoupePanel];
    }
    else if([aNotification object] == [self window])
    {
        SetSystemUIMode(kUIModeNormal, 0);
		if([[session valueForKey: @"loupe"] boolValue])
		{
			[NSCursor hide];
		}
		[self refreshLoupePanel];
    }
}



- (void)windowDidResignKey:(NSNotification *)aNotification
{
    if([aNotification object] == exposeBezel)
    {
        [exposeBezel orderOut: self];
    }
	
	if([aNotification object] == [self window])
	{
		[NSCursor unhide];
		[self refreshLoupePanel];
		[[infoWindow parentWindow] removeChildWindow: infoWindow];
		[infoWindow orderOut: self];
	}
	
	if([aNotification object] == bezelWindow)
	{
		[[infoWindow parentWindow] removeChildWindow: infoWindow];
		[infoWindow orderOut: self];
	}
}


- (NSSize)windowWillResize:(NSWindow *)resizeWindow toSize:(NSSize)newSize
{
	if(resizeWindow != [self window])
	{
		return newSize;
	}
	
	if([resizeWindow showsResizeIndicator])
	{
		return newSize;
	}
	else
	{
		return [resizeWindow frame].size;
	}
}



- (void)windowDidResize:(NSNotification *)aNotification
{
	BOOL statusBar;
    if([aNotification object] == [self window])
    {
		NSRect frame = [[self window] frame];
		[[infoWindow parentWindow] removeChildWindow: infoWindow];
        [infoWindow orderOut: self];

		if([[session valueForKey: TSSTFullscreen] boolValue])
		{
			statusBar = NO;
			NSRect bezelRect = [bezelWindow frame];
			bezelRect.origin.x = NSWidth(frame) / 2 - NSWidth(bezelRect) / 2 + NSMinX(frame);
			bezelRect.origin.y = NSMinY(frame) - 1.5; 
			[bezelWindow setFrameOrigin: bezelRect.origin];
		}
		else 
		{
			statusBar = [[[NSUserDefaults standardUserDefaults] valueForKey: TSSTStatusbarVisible] boolValue];
		}

		
        if(statusBar)
        {
			NSPoint mouseLocation = [[self window] convertScreenToBase: [NSEvent mouseLocation]];
            NSRect progressRect = [[[self window] contentView] convertRect: [progressBar progressRect] fromView: progressBar];
			BOOL cursorInside = NSMouseInRect(mouseLocation, progressRect, [[[self window] contentView] isFlipped]);
			if(cursorInside && ![pageView inLiveResize])
			{
				[self infoPanelSetupAtPoint: mouseLocation];
				[[self window] addChildWindow: infoWindow ordered: NSWindowAbove];
			}
        }
	}
}



/*	This method deals with window resizing.  It is called every time the user clicks 
	the nice little plus button in the upper left of the window.
	It is also called optionally every time the page is turned.  That is if the
	user has auto resize enabled. */
- (NSRect)windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame
{
    if(sender == [self window])
    {
        defaultFrame = [self optimalPageViewRectForRect: defaultFrame];
    }
	
    return defaultFrame;
}



/*	Added for 10.6 compatibility.  As I can no longer just call 
	windowWillUseStandardFrame:defaultRect: */
- (NSRect)optimalPageViewRectForRect:(NSRect)boundingRect
{
	NSSize maxImageSize = [pageView combinedImageSizeForZoom: [[session valueForKey: TSSTZoomLevel] floatValue]];
	float vertOffset = [[self window] contentBorderThicknessForEdge: NSMinYEdge] + [(DTSessionWindow *)[self window] toolbarHeight];
	if([pageScrollView hasHorizontalScroller])
	{
		vertOffset += NSHeight([[pageScrollView horizontalScroller] frame]);
	}
	float horOffset = [pageScrollView hasVerticalScroller] ? NSWidth([[pageScrollView verticalScroller] frame]) : 0;
	
	NSRect correctedFrame = boundingRect;
	correctedFrame.size.width -= horOffset;
	correctedFrame.size.height -= vertOffset;
	NSSize newSize;
	if([[session valueForKey: TSSTPageScaleOptions] intValue] == 1 && ![self currentPageIsText])
	{
		float scale;
		if( maxImageSize.width < NSWidth(correctedFrame) && maxImageSize.height < NSHeight(correctedFrame))
		{
			scale = 1;
		}
		else if( NSWidth(correctedFrame) / NSHeight(correctedFrame) < maxImageSize.width / maxImageSize.height)
		{
			scale = NSWidth(correctedFrame) / maxImageSize.width;
		}
		else
		{
			scale = NSHeight(correctedFrame) / maxImageSize.height;
		}
		newSize = scaleSize(maxImageSize, scale);
	}
	else
	{
		newSize.width = maxImageSize.width < NSWidth(correctedFrame) ? maxImageSize.width : NSWidth(correctedFrame);
		newSize.height = maxImageSize.height < NSHeight(correctedFrame) ? maxImageSize.height : NSHeight(correctedFrame);
	}
	
	NSSize minSize = [[self window] minSize];
	newSize.width = newSize.width < minSize.width ? minSize.width : newSize.width;
	newSize.height = newSize.height < minSize.height ? minSize.height : newSize.height;
	NSRect windowFrame = [[self window] frame];
	NSPoint centerPoint = NSMakePoint(NSMinX(windowFrame) + NSWidth(windowFrame) / 2, 
									  NSMinY(windowFrame) + NSHeight(windowFrame) / 2);
	newSize.width += horOffset;
	newSize.height += vertOffset;
	NSRect screenRect = [[[self window] screen] visibleFrame];
	
	if((NSMinX(windowFrame) + newSize.width) > NSWidth(screenRect))
	{
		windowFrame.origin.x = NSWidth(screenRect) - newSize.width;
	}
	
	windowFrame.origin.y += NSHeight(windowFrame) - newSize.height;
	if((NSMinY(windowFrame) + newSize.height) > NSHeight(screenRect))
	{
		windowFrame.origin.y = NSHeight(screenRect) - newSize.height;
	}
	
	boundingRect = NSMakeRect( centerPoint.x - newSize.width / 2, centerPoint.y - newSize.height / 2, newSize.width, newSize.height);
	boundingRect.origin.x = boundingRect.origin.x > NSMinX(screenRect) ? boundingRect.origin.x : NSMinX(screenRect);
	boundingRect.origin.y = boundingRect.origin.y > NSMinY(screenRect) ? boundingRect.origin.y : NSMinY(screenRect);
	
	return boundingRect;
}


- (void)resizeView
{
    [pageView resizeView];
}


- (BOOL)currentPageIsText
{
	TSSTPage * page = [[pageController selectedObjects] objectAtIndex: 0];
	return [[page valueForKey: @"text"] boolValue];
}


- (void)toolbarWillAddItem:(NSNotification *)notification
{
	NSToolbarItem * item = [[notification userInfo] objectForKey: @"item"];
	
	if([[item label] isEqualToString: @"Page Scaling"])
	{
		[[item view] bind: @"selectedIndex" toObject: self withKeyPath: @"session.scaleOptions" options: nil];
	}
	else if([[item label] isEqualToString: @"Page Order"])
	{
		[[item view] bind: @"selectedIndex" toObject: self withKeyPath: @"session.pageOrder" options: nil];
	}
	else if([[item label] isEqualToString: @"Page Layout"])
	{
		[[item view] bind: @"selectedIndex" toObject: self withKeyPath: @"session.twoPageSpread" options: nil];
	}
	else if([[item label] isEqualToString: @"Loupe"])
	{
		[[item view] bind: @"value" toObject: self withKeyPath: @"session.loupe" options: nil];
	}
	else if([[item label] isEqualToString: @"Fullscreen"])
	{
		[[item view] bind: @"value" toObject: self withKeyPath: @"session.fullscreen" options: nil];
	}
}


@end

