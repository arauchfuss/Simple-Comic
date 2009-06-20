/*	
Copyright (c) 2007 Dancing Tortoise Software
 
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
#import "UKXattrMetadataStore.h"
#import "SimpleComicAppDelegate.h"
#import "TSSTSessionWindowController.h"
#import "TSSTPageView.h"
#import "TSSTSortDescriptor.h"
#import "TSSTImageUtilities.h"
#import "TSSTPage.h"
#import "TSSTManagedGroup.h"
#import "TSSTCRTProgressBar.h"
#import "TSSTInfoWindow.h"
#import "TSSTThumbnailView.h"
#import "TSSTManagedSession.h"
#import "TSSTFullscreenProgressBar.h"


@implementation TSSTSessionWindowController


@synthesize pageTurn, pageNames, pageSortDescriptor;


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
}



/*  Inits the window controller and sets the session.
    If this is a new session as opposed to a saved session
    then the window cascades */
- (id)initWithSession:(TSSTManagedSession *)aSession
{
    self = [super init];
    if (self != nil)
    {
		mouseMovedTimer = nil;
		closing = NO;
        bezelAnimation = nil;
        session = [aSession retain];
        BOOL cascade = [session valueForKey: @"position"] ? NO : YES;
        [self setShouldCascadeWindows: cascade];
        [session setValue: [NSNumber numberWithBool: NO] forKey: @"loupe"];
		TSSTSortDescriptor * fileNameSort = [[TSSTSortDescriptor alloc] initWithKey: @"imagePath" ascending: YES];
		TSSTSortDescriptor * archivePathSort = [[TSSTSortDescriptor alloc] initWithKey: @"group.name" ascending: YES];
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
    [pageScrollView setPostsFrameChangedNotifications: YES];
    /* This needs to be set as the window subclass that the expose window
        uses has mouse events turned off by default */
    [exposeBezel setIgnoresMouseEvents: NO];
    [exposeBezel setFloatingPanel: YES];
    [[self window] setAcceptsMouseMovedEvents: YES];
    /*  This needs to be set so that mouse moved events from the fullscreen window
        are passed to its delegate, this window controller */
    [fullscreenWindow setNextResponder: self];
    [fullscreenWindow setAcceptsMouseMovedEvents: YES];
        
    [pageController setSelectionIndex: [[session valueForKey: @"selection"] intValue]];

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
//	[self fullscreen];
}



- (void)dealloc
{
	[(TSSTThumbnailView *)exposeView setDataSource: nil];
    [bezelAnimation stopAnimation];    
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
    
    [session removeObserver: self forKeyPath: TSSTFullscreen];
    [session removeObserver: self forKeyPath: TSSTPageOrder];
    [session removeObserver: self forKeyPath: TSSTPageScaleOptions];
    [session removeObserver: self forKeyPath: TSSTTwoPageSpread];
	[session removeObserver: self forKeyPath: @"loupe"];
    [session unbind: TSSTViewRotation];
    [session unbind: @"selection"];
    
    [progressBar removeObserver: self forKeyPath: @"currentValue"];
    [progressBar unbind: @"currentValue"];
    [progressBar unbind: @"maxValue"];
    [progressBar unbind: @"leftToRight"];
	
	[fullscreenProgressBar removeObserver: self forKeyPath: @"currentValue"];
    [fullscreenProgressBar unbind: @"currentValue"];
    [fullscreenProgressBar unbind: @"maxValue"];
    [fullscreenProgressBar unbind: @"leftToRight"];
        
    [pageView setDataSource: nil];
	[pageSortDescriptor release];
    [session release];
    [pageNames release];
    [super dealloc];
}



/*  Observes changes to the page controller.  Changes are reflected by the 
    page view.  */
- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object 
						change:(NSDictionary *)change 
					   context:(void *)context
{
    if(closing)
	{
		return;
	}
	
	
    if([[pageController arrangedObjects] count] <= 0)
    {
        SetSystemUIMode(kUIModeNormal, 0);
        [[NSApp delegate] endSession: self];
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
	NSPoint location = [theEvent locationInWindow];
	NSRect progressRect;
	
	if([[session valueForKey: TSSTFullscreen] boolValue] && [fullscreenWindow isKeyWindow])
	{
		if(mouseMovedTimer)
		{
			[mouseMovedTimer invalidate];
			mouseMovedTimer = nil;
		}
		
		mouseMovedTimer = [NSTimer scheduledTimerWithTimeInterval: 2 target: self  selector: @selector(hideCursor) userInfo: nil repeats: NO];
		
		if([theEvent window] == bezelWindow)
		{
			progressRect = [fullscreenProgressBar convertRect: [fullscreenProgressBar progressRect] toView: nil];
			if(NSMouseInRect(location, progressRect, [fullscreenProgressBar isFlipped]))
			{
				[self infoPanelSetupAtPoint: location];
			}		
		}
		else
		{
			NSRect fullscreenFrame = [fullscreenWindow frame];
			NSRect bezelFrame = [bezelWindow frame];
			if(NSMouseInRect(location, NSMakeRect(0, 0, NSWidth(fullscreenFrame), 4), NO))
			{
				[fullscreenWindow addChildWindow: bezelWindow ordered: NSWindowAbove];
			}
			else if(!NSMouseInRect(location, bezelFrame, NO))
			{
				[fullscreenWindow removeChildWindow: bezelWindow];
				[bezelWindow orderOut: self];
			}
		}
		
	}
	else
	{
		progressRect = [progressBar convertRect: [progressBar progressRect] toView: nil];
		if(NSMouseInRect(location, progressRect, [progressBar isFlipped]))
		{
			[self infoPanelSetupAtPoint: location];
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
    NSWindow * currentWindow = [[session valueForKey: TSSTFullscreen] boolValue] ? fullscreenWindow : [self window];
    NSPoint localPoint = [pageView convertPoint: [currentWindow convertScreenToBase: mouse] fromView: nil];
	NSPoint scrollPoint = [pageScrollView convertPoint: [currentWindow convertScreenToBase: mouse] fromView: nil];
    if(NSMouseInRect(scrollPoint, [pageScrollView bounds], [pageScrollView isFlipped]) && loupe)
    {
		if(![loupeWindow isVisible])
		{
			[currentWindow addChildWindow: loupeWindow ordered: NSWindowAbove];
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
	TSSTCRTProgressBar * bar;
	if([[session valueForKey: TSSTFullscreen] boolValue])
	{
		bar = fullscreenProgressBar;
		[[infoWindow contentView] setBordered: YES];
	}
	else
	{
		bar = progressBar;
		[[infoWindow contentView] setBordered: NO];
	}
	
	cursorPoint = [bar convertPoint: point fromView: nil];
	point.y = (NSMaxY([bar frame]) - 4.5);
	index = [bar indexForPoint: cursorPoint];

    NSImage * thumb = [self imageForPageAtIndex: index];
    NSSize thumbSize = sizeConstrainedByDimension([thumb size], 128);
	
    [infoPicture setFrameSize: thumbSize];
    [infoPicture setImage: thumb];
	
    cursorPoint = [[bar window] convertBaseToScreen: point];
	
    [infoWindow caretAtPoint: cursorPoint size: NSMakeSize(thumbSize.width + 20, thumbSize.height + 25) 
			   withLimitLeft: NSMinX([[bar window] frame]) 
					   right: NSMaxX([[bar window] frame])];
}



#pragma mark -
#pragma mark Actions


- (IBAction)exportPage:(id)sender
{
	
}



- (IBAction)removePages:(id)sender
{
    NSManagedObject * page = [[pageController selectedObjects] objectAtIndex: 0];
    [pageController removeObject: page];
    [[self managedObjectContext] deleteObject: page];
}



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
    int previousZoom = [[session valueForKey: TSSTZoomLevel] intValue];
    if(scalingOption != 0)
    {
        float factor = NSWidth([pageView imageBounds]) / [pageView combinedImageSizeForZoomLevel: 0].width;
        previousZoom = (factor * 10) - 10;
    }
    
    [session setValue: [NSNumber numberWithInt: ++previousZoom] forKey: TSSTZoomLevel];
	[session setValue: [NSNumber numberWithInt: 0] forKey: TSSTPageScaleOptions];
	
    [pageView resizeView];
    [self refreshLoupePanel];
}



- (IBAction)zoomOut:(id)sender
{
    int scalingOption = [[session valueForKey: TSSTPageScaleOptions] intValue];
    int previousZoom = [[session valueForKey: TSSTZoomLevel] intValue];
    if(scalingOption != 0)
    {
        float factor = NSWidth([pageView imageBounds]) / [pageView combinedImageSizeForZoomLevel: 0].width;
        previousZoom = (factor * 10) - 10;
    }
    
    [session setValue: [NSNumber numberWithInt: (previousZoom > -9 ? previousZoom - 1 : previousZoom)] forKey: TSSTZoomLevel];
	[session setValue: [NSNumber numberWithInt: 0] forKey: TSSTPageScaleOptions];
	
    [pageView resizeView];
    [self refreshLoupePanel];
}



- (IBAction)zoomReset:(id)sender
{
	[session setValue: [NSNumber numberWithInt: 0] forKey: TSSTPageScaleOptions];
    [session setValue: [NSNumber numberWithInt: 0] forKey: TSSTZoomLevel];
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
	NSWindow * current = [fullscreenWindow isVisible] ? fullscreenWindow : [self window];
	[NSApp beginSheet: jumpPanel modalForWindow: current modalDelegate: self didEndSelector: @selector(closeSheet:) contextInfo: NULL];
}



- (IBAction)cancleJumpPanel:(id)sender
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



- (IBAction)setArchiveIcon:(id)sender
{
	TSSTPage * currentPage = [[pageController selectedObjects] objectAtIndex: 0];
	TSSTManagedGroup * currentGroup = [currentPage valueForKey: @"group"];
	if(currentGroup == [currentGroup topLevelGroup])
	{
		int coverIndex = [[currentPage valueForKey: @"index"] intValue];
		NSData * coverIndexData = [NSArchiver archivedDataWithRootObject: [NSNumber numberWithInt: coverIndex]];
		NSString * archivePath = [[currentGroup valueForKey: @"path"] stringByStandardizingPath];
		[UKXattrMetadataStore setData: coverIndexData forKey: @"QCCoverIndex" atPath: archivePath traverseLink: NO];
		[NSTask launchedTaskWithLaunchPath: @"/usr/bin/touch" arguments: [NSArray arrayWithObject: archivePath]];
	}
}



//- (IBAction)addBookmark:(id)sender
//{
//	[[NSApp delegate] addBookmarkWithSession: [self session]];
//}



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
	
    BOOL currentAllowed = [pageOne hasAllowedAspectRatio] && 
        !(index == 0 &&[[defaults valueForKey: TSSTLonelyFirstPage] boolValue]);
    
    if(currentAllowed && [[session valueForKey: TSSTTwoPageSpread] boolValue] && [pageTwo hasAllowedAspectRatio])
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
    
    [self resizeWindow];

    [self refreshLoupePanel];
}



- (void)resizeWindow
{
    if(![[session valueForKey: TSSTFullscreen] boolValue] &&
       [[[NSUserDefaults standardUserDefaults] valueForKey: TSSTWindowAutoResize] boolValue])
    {
        NSRect allowedRect = [[[self window] screen] visibleFrame];
        NSRect zoomFrame = [self windowWillUseStandardFrame: [self window] defaultFrame: allowedRect];
        [[self window] setFrame: zoomFrame display: YES animate: NO];
    }
}



- (void)fullscreen
{
    NSRect contentRect = NSZeroRect;
    [pageScrollView retain];
    if(mouseMovedTimer)
	{
		[mouseMovedTimer invalidate];
		mouseMovedTimer = nil;
	}
	
    if([[session valueForKey: TSSTFullscreen] boolValue])
    {
        NSValue * rectangleValue = [NSValue valueWithRect: [[self window] frame]];
        NSData * rectData = [NSArchiver archivedDataWithRootObject: rectangleValue];
        [session setValue: rectData forKey: @"position" ];
        
        SetSystemUIMode(kUIModeAllHidden, kUIOptionAutoShowMenuBar);
        [[self window] orderOut: self];
        [fullscreenWindow setFrame: [[[self window] screen] frame] display: NO];
        [pageScrollView removeFromSuperview];
        [[fullscreenWindow contentView] addSubview: pageScrollView];
        contentRect.size = [[pageScrollView window] frame].size;
        [pageScrollView setFrame: contentRect];
        [fullscreenWindow makeKeyAndOrderFront: self];
		if(mouseMovedTimer)
		{
			[mouseMovedTimer invalidate];
			mouseMovedTimer = nil;
		}
		mouseMovedTimer = [NSTimer scheduledTimerWithTimeInterval: 2 target: self  selector: @selector(hideCursor) userInfo: nil repeats: NO];
		
    }
    else
    {
        SetSystemUIMode(kUIModeNormal, 0);
        [fullscreenWindow orderOut: self];
        [pageScrollView removeFromSuperview];
        [[[self window] contentView] addSubview: pageScrollView];
        contentRect.size = [[pageView window] contentRectForFrameRect: [[self window] frame]].size;
        contentRect.origin.y = [[self window] contentBorderThicknessForEdge: NSMinYEdge];
        contentRect.size.height -= contentRect.origin.y;
        [pageScrollView setFrame: contentRect];
        [self adjustStatusBar];
        [self resizeWindow];
        [[self window] makeKeyAndOrderFront: self];
    }
	
	[[infoWindow parentWindow] removeChildWindow: infoWindow];
	[infoWindow orderOut: self];
	
    [[loupeWindow parentWindow] removeChildWindow: loupeWindow];
    [loupeWindow orderOut: self];
	
    [self refreshLoupePanel];
    [pageScrollView release];
}



- (void)scaleToWindow
{
    BOOL hasVert = NO;
    BOOL hasHor = NO;

	switch ([[session valueForKey: TSSTPageScaleOptions] intValue])
	{
	case  0:
		hasVert = YES;
		hasHor = YES;
		break;
	case  2:
		[session setValue: [NSNumber numberWithInt: 0] forKey: TSSTZoomLevel];
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
		[session setValue: [NSNumber numberWithInt: 0] forKey: TSSTZoomLevel];
		break;
	}
	
	if(![[[NSUserDefaults standardUserDefaults] valueForKey: TSSTScrollersVisible] boolValue])
    {
		hasVert = NO;
		hasHor = NO;
	}
    
    [pageScrollView setHasVerticalScroller: hasVert];
    [pageScrollView setHasHorizontalScroller: hasHor];
    [self resizeWindow];
    [pageView resizeView];
    [self refreshLoupePanel];
}


- (void)adjustStatusBar
{
    
    if([[session valueForKey: TSSTFullscreen] boolValue])
    {
        return;
    }
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSRect scrollViewRect;
    BOOL statusBar = [[defaults valueForKey: TSSTStatusbarVisible] boolValue];
    if(statusBar)
    {
        scrollViewRect = [[[self window] contentView] frame];
        scrollViewRect = NSMakeRect(NSMinX(scrollViewRect), 
                                    NSMinY(scrollViewRect) + 33,
                                    NSWidth(scrollViewRect),
                                    NSHeight(scrollViewRect) - 33);
        [[self window] setContentBorderThickness: 33 forEdge: NSMinYEdge];
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
	BOOL current = [[[pageController arrangedObjects] objectAtIndex: selectionIndex] hasAllowedAspectRatio] &&
        !(selectionIndex == 0 &&[[defaults valueForKey: TSSTLonelyFirstPage] boolValue]);
	BOOL next = [[[pageController arrangedObjects] objectAtIndex: (selectionIndex + 1)] hasAllowedAspectRatio];
	
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

        BOOL previousPage = [[[pageController arrangedObjects] objectAtIndex: (selectionIndex - 1)] hasAllowedAspectRatio];
		BOOL pageBeforeLast = [[[pageController arrangedObjects] objectAtIndex: (selectionIndex - 2)] hasAllowedAspectRatio] && 
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


#pragma mark Menus


- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
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
    else if([menuItem tag] == 403)
    {
        state = [[session valueForKey: TSSTPageScaleOptions] intValue] == 3 ? NSOnState : NSOffState;
        [menuItem setState: state];
    }
    return YES;
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
	[mouseMovedTimer invalidate];
	mouseMovedTimer = nil;
    [NSCursor unhide];
    SetSystemUIMode(kUIModeNormal, 0);
	closing = YES;
}


- (BOOL)windowShouldClose:(id)sender
{
	[self prepareToEnd];
    [[NSApp delegate] endSession: self];
    return YES;
}



- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
    if([aNotification object] == fullscreenWindow)
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
    }
    
    if([aNotification object] == [self window])
    {
        SetSystemUIMode(kUIModeNormal, 0);
		if([[session valueForKey: @"loupe"] boolValue])
		{
			[NSCursor hide];
		}
    }
}



- (void)windowDidResignKey:(NSNotification *)aNotification
{
    if([aNotification object] == exposeBezel)
    {
        [exposeBezel orderOut: self];
    }
	
	if([aNotification object] == [self window] || [aNotification object] == fullscreenWindow)
	{
		[NSCursor unhide];
	}
}



- (void)windowDidResize:(NSNotification *)aNotification
{
    NSRect frame;
    if([aNotification object] == [self window])
    {
        BOOL statusBar = [[[NSUserDefaults standardUserDefaults] valueForKey: TSSTStatusbarVisible] boolValue];
        [[infoWindow parentWindow] removeChildWindow: infoWindow];
        [infoWindow orderOut: self];
		
        if(statusBar)
        {
			NSPoint mouseLocation = [[self window] convertScreenToBase: [NSEvent mouseLocation]];
            NSRect progressRect = [[[self window] contentView] convertRect: [progressBar progressRect] fromView: progressBar];
			BOOL cursorInside = NSMouseInRect(mouseLocation, progressRect, [[[self window] contentView] isFlipped]);
			if(cursorInside)
			{
				[self infoPanelSetupAtPoint: mouseLocation];
				[[self window] addChildWindow: infoWindow ordered: NSWindowAbove];
			}
        }
    }
    else if([aNotification object] == fullscreenWindow)
    {
        frame = [fullscreenWindow frame];
        NSRect bezelRect = [bezelWindow frame];
        bezelRect.origin.x = NSWidth(frame) / 2 - NSWidth(bezelRect) / 2 + NSMinX(frame);
        bezelRect.origin.y = NSMinY(frame) - 1.5; 
        [bezelWindow setFrame: bezelRect display: NO];
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
        NSSize maxImageSize = [pageView combinedImageSizeForZoomLevel: [[session valueForKey: TSSTZoomLevel] intValue]];
        float vertOffset = [[self window] contentBorderThicknessForEdge: NSMinYEdge] + [self toolbarHeight];
        if([pageScrollView hasHorizontalScroller])
        {
            vertOffset += NSHeight([[pageScrollView horizontalScroller] frame]);
        }
        float horOffset = [pageScrollView hasVerticalScroller] ? NSWidth([[pageScrollView verticalScroller] frame]) : 0;
        
        NSRect correctedFrame = defaultFrame;
        correctedFrame.size.width -= horOffset;
        correctedFrame.size.height -= vertOffset;
        NSSize newSize;
        if([[session valueForKey: TSSTPageScaleOptions] intValue] == 1)
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
		
        defaultFrame = NSMakeRect( centerPoint.x - newSize.width / 2, centerPoint.y - newSize.height / 2, newSize.width, newSize.height);
        defaultFrame.origin.x = defaultFrame.origin.x > NSMinX(screenRect) ? defaultFrame.origin.x : NSMinX(screenRect);
        defaultFrame.origin.y = defaultFrame.origin.y > NSMinY(screenRect) ? defaultFrame.origin.y : NSMinY(screenRect);
    }
	
    return defaultFrame;
}



- (void)resizeView
{
    [pageView resizeView];
}



- (float)toolbarHeight
{
    return NSHeight([[self window] frame]) - NSHeight([[[self window] contentView] frame]);
}



@end


