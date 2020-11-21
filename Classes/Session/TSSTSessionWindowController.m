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

	TSSTSessionWindowController.m
*/

#import <XADMaster/XADArchive.h>
#import "UKXattrMetadataStore.h"
#import "SimpleComicAppDelegate.h"
#import "TSSTSessionWindowController.h"
#import "TSSTPageView.h"
#import "TSSTSortDescriptor.h"
#import "TSSTImageUtilities.h"
#import "TSSTPage.h"
#import "TSSTManagedGroup.h"
#import "TSSTManagedSession.h"

#import "Simple_Comic-Swift.h"

NSString * const TSSTMouseDragNotification = @"SCMouseDragNotification";

@implementation TSSTSessionWindowController
{
	/** The session object used to maintain settings */
	TSSTManagedSession * session;
	
	/** This var is bound to the session window name */
	NSString *pageNames;
	NSInteger pageTurn;
	
	/** Exactly what it sounds like */
	NSArray<TSSTSortDescriptor*> *pageSortDescriptor;
	
	/** Manages the cursor hiding while in fullscreen */
	NSTimer *mouseMovedTimer;
	
	BOOL newSession;
	
	PageSelectionMode pageSelectionInProgress;
	CGFloat savedZoom;
}

@synthesize pageTurn, pageNames, pageSortDescriptor;
@synthesize pageController;
@synthesize pageView;
@synthesize pageScrollView;
@synthesize jumpPanel;
@synthesize jumpField;
@synthesize progressBar;
@synthesize infoWindow;
@synthesize infoPicture;
@synthesize loupeWindow;
@synthesize zoomView;
@synthesize exposeBezel;
@synthesize exposeView;
@synthesize thumbnailPanel;

- (instancetype)initWithSession:(TSSTManagedSession *)aSession
{
	self = [super init];
	if (self != nil)
	{
		pageTurn = 0;
		pageSelectionInProgress = PageSelectionModeNone;
		mouseMovedTimer = nil;
		session = aSession;
		BOOL cascade = session.position ? NO : YES;
		[self setShouldCascadeWindows: cascade];
		/* Make sure that the session does not start out in fullscreen, nor with the loupe enabled. */
		session.loupe = NO;
		/* Images are sorted by group and then image name. */
		TSSTSortDescriptor * fileNameSort = [[TSSTSortDescriptor alloc] initWithKey: @"imagePath" ascending: YES];
		TSSTSortDescriptor * archivePathSort = [[TSSTSortDescriptor alloc] initWithKey: @"group.path" ascending: YES];
		self.pageSortDescriptor = @[archivePathSort, fileNameSort];
	}
	
	return self;
}


- (NSString *)windowNibName
{
	return @"TSSTSessionWindow";
}


- (void)windowDidLoad
{
	if ([[NSUserDefaults standardUserDefaults] boolForKey: TSSTUnifiedTitlebar])
	{
		[super windowDidLoad];
		self.window.titleVisibility = NSWindowTitleHidden;
	}
}


/*  Sets up all of the observers and bindings. */
- (void)awakeFromNib
{
	[super awakeFromNib];
	/* This needs to be set as the window subclass that the expose window
	 uses has mouse events turned off by default */
	[exposeBezel setIgnoresMouseEvents: NO];
	[exposeBezel setFloatingPanel: YES];
	[exposeBezel setWindowController: self];
	[[self window] setAcceptsMouseMovedEvents: YES];
	[pageController setSelectionIndex: session.selection];
	
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults addObserver: self forKeyPath: TSSTConstrainScale options: 0 context: nil];
	[defaults addObserver: self forKeyPath: TSSTStatusbarVisible options: 0 context: nil];
	[defaults addObserver: self forKeyPath: TSSTScrollersVisible options: 0 context: nil];
	[defaults addObserver: self forKeyPath: TSSTBackgroundColor options: 0 context: nil];
	[defaults addObserver: self forKeyPath: TSSTLoupeDiameter options: 0 context: nil];
	[defaults addObserver: self forKeyPath: TSSTLoupePower options: 0 context: nil];
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
	
	[pageView bind: TSSTViewRotation toObject: session withKeyPath: TSSTViewRotation options: nil];
	NSTrackingArea * newArea = [[NSTrackingArea alloc] initWithRect: [progressBar progressRect]
															options: NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow | NSTrackingActiveInActiveApp
															  owner: self
														   userInfo: @{@"purpose": @"normalProgress"}];
	[progressBar addTrackingArea: newArea];
	[jumpField setDelegate: self];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMouseDragged:) name:TSSTMouseDragNotification object:nil];
	
	[self restoreSession];
}


- (void)dealloc
{
	[(TSSTThumbnailView *)exposeView setDataSource: nil];
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults removeObserver: self forKeyPath: TSSTStatusbarVisible];
	[defaults removeObserver: self forKeyPath: TSSTScrollersVisible];
	[defaults removeObserver: self forKeyPath: TSSTBackgroundColor];
	[defaults removeObserver: self forKeyPath: TSSTConstrainScale];
	[defaults removeObserver: self forKeyPath: TSSTLoupeDiameter];
	[defaults removeObserver: self forKeyPath: TSSTLoupePower];
	[pageController removeObserver: self forKeyPath: @"selectionIndex"];
	[pageController removeObserver: self forKeyPath: @"arrangedObjects.@count"];
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[progressBar removeObserver: self forKeyPath: @"currentValue"];
	[progressBar unbind: @"currentValue"];
	[progressBar unbind: @"maxValue"];
	[progressBar unbind: @"leftToRight"];
	
	[pageView setSessionController: nil];
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
	
	if([keyPath isEqualToString: TSSTScrollersVisible])
	{
		[self scaleToWindow];
	}
	else if([keyPath isEqualToString: @"currentValue"])
	{
		if(object == progressBar)
		{
			[pageController setSelectionIndex: [progressBar currentValue]];
		}
	}
	else if([keyPath isEqualToString: @"arrangedObjects.@count"])
	{
		[NSThread detachNewThreadSelector: @selector(processThumbs) toTarget: exposeView withObject: nil];
		[self changeViewImages];
	}
	else if([keyPath isEqualToString: TSSTPageOrder])
	{
		[defaults setBool: session.pageOrder forKey: TSSTPageOrder];
		[(TSSTThumbnailView *)exposeView setNeedsDisplay: YES];
		[(TSSTThumbnailView *)exposeView buildTrackingRects];
		[self changeViewImages];
	}
	else if([keyPath isEqualToString: TSSTPageScaleOptions])
	{
		[defaults setInteger: session.scaleOptions forKey: TSSTPageScaleOptions];
		[self scaleToWindow];
	}
	else if([keyPath isEqualToString: TSSTTwoPageSpread])
	{
		[defaults setBool: session.twoPageSpread forKey: TSSTTwoPageSpread];
		[self changeViewImages];
	}
	else if([keyPath isEqualToString: TSSTBackgroundColor])
	{
		NSColor * color = [NSKeyedUnarchiver unarchiveObjectWithData: [defaults valueForKey: TSSTBackgroundColor]];
		[pageScrollView setBackgroundColor: color];
	}
	else if([keyPath isEqualToString: TSSTStatusbarVisible])
	{
		[self adjustStatusBar];
	}
	else if([keyPath isEqualToString: TSSTLoupeDiameter])
	{
		NSInteger loupeDiameter = [defaults integerForKey: TSSTLoupeDiameter];
		[loupeWindow resizeToDiameter: loupeDiameter];
	}
	else if([keyPath isEqualToString: @"loupe"])
	{
		[self refreshLoupePanel];
	}
	else if([keyPath isEqualToString: TSSTLoupePower])
	{
		[self refreshLoupePanel];
	}
	else
	{
		[self changeViewImages];
	}
}


#pragma mark - Progress Bar


- (NSImage *)imageForPageAtIndex:(NSInteger)index
{
	return [[pageController arrangedObjects][index] valueForKey: @"thumbnail"];
}


- (NSString *)nameForPageAtIndex:(NSInteger)index
{
	return [[pageController arrangedObjects][index] valueForKey: @"name"];
}


#pragma mark - Event handling


- (void)mouseMoved:(NSEvent *)theEvent
{
	NSRect progressRect;
	NSPoint windowLocation = [theEvent locationInWindow];
	progressRect = [progressBar convertRect: [progressBar progressRect] toView: nil];
	if(NSMouseInRect(windowLocation, progressRect, [progressBar isFlipped]))
	{
		[self infoPanelSetupAtPoint: windowLocation];
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
}


- (void)mouseExited:(NSEvent *)theEvent
{
	if([theEvent trackingArea])
	{
		[[infoWindow parentWindow] removeChildWindow: infoWindow];
		[infoWindow orderOut: self];
	}
}


/* Handles mouse drag notifications relayed from progressbar */
- (void)handleMouseDragged:(NSNotification*)notification
{
	[infoWindow orderOut:self];
}


- (void)refreshLoupePanel
{
	BOOL loupe = session.loupe;
	NSPoint mouse = [NSEvent mouseLocation];
	
	NSRect point = NSMakeRect(mouse.x, mouse.y, 0, 0);
	NSPoint localPoint = [pageView convertPoint: [[self window] convertRectFromScreen: point].origin fromView: nil];
	NSPoint scrollPoint = [pageScrollView convertPoint: [[self window] convertRectFromScreen: point].origin fromView: nil];
	if(NSMouseInRect(scrollPoint, [pageScrollView bounds], [pageScrollView isFlipped])
	   && loupe
	   && [[self window] isKeyWindow]
	   && pageSelectionInProgress == PageSelectionModeNone)
	{
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
	NSInteger index;
	DTPolishedProgressBar * bar = progressBar;
	
	[[infoWindow contentView] setBordered: NO];
	point.y = (NSMaxY([bar frame]) - 6);
	
	cursorPoint = [bar convertPoint: point fromView: nil];
	index = [bar indexForPoint: cursorPoint];
	
	NSImage * thumb = [self imageForPageAtIndex: index];
	NSSize thumbSize = sizeConstrainedByDimension([thumb size], 128);
	
	[infoPicture setFrameSize: thumbSize];
	[infoPicture setImage: thumb];
	
	cursorPoint = [[bar window] convertRectToScreen: (NSRect){point, NSZeroSize}].origin;
	
	[infoWindow caretAtPoint: cursorPoint size: NSMakeSize(thumbSize.width, thumbSize.height)
			   withLimitLeft: NSMinX([[bar window] frame])
					   right: NSMaxX([[bar window] frame])];
}


#pragma mark - Actions


- (IBAction)changeTwoPage:(id)sender
{
	BOOL spread = !session.twoPageSpread;
	session.twoPageSpread = spread;
}


- (IBAction)changePageOrder:(id)sender
{
	BOOL pageOrder = !session.pageOrder;
	session.pageOrder = pageOrder;
}


- (IBAction)changeScaling:(id)sender
{
	DTPageScaling scaleType = [sender tag] % 400;
	session.scaleOptions = scaleType;
}


- (IBAction)turnPage:(id)sender
{
	NSInteger segmentTag = [[sender cell] tagForSegment: [sender selectedSegment]];
	if(segmentTag == 701)
	{
		[self pageLeft: self];
	}
	else if(segmentTag == 702)
	{
		[self pageRight: self];
	}
}

- (IBAction)pageEnd:(id)sender
{
	BOOL right = ([sender selectedSegment] > 0);
	if(session.pageOrder ^ right)
	{
		[self firstPage:sender];
	}
	else
	{
		[self lastPage:sender];
	}
}

/*! Method flips the page to the right calling nextPage or previousPage
	depending on the prefered page ordering.
*/
- (IBAction)pageRight:(id)sender
{
	[self setPageTurn: 2];
	if(session.pageOrder)
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
	
	if(session.pageOrder)
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
	if(session.pageOrder)
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
	if(session.pageOrder)
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
	NSUInteger index;
	if(session.pageOrder)
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
	NSUInteger index;
	if(!session.pageOrder)
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
	NSInteger segmentTag = [[sender cell] tagForSegment: [sender selectedSegment]];
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
	int scalingOption = session.scaleOptions;
	CGFloat previousZoom = session.zoomLevel;
	if(scalingOption != 0)
	{
		previousZoom = NSWidth([pageView imageBounds]) / [pageView combinedImageSizeForZoom: 1].width;
	}
	
	previousZoom += 0.1;
	session.zoomLevel = previousZoom;
	session.scaleOptions = 0;
	
	[pageView resizeView];
	[self refreshLoupePanel];
}

- (IBAction)zoomOut:(id)sender
{
	int scalingOption = session.scaleOptions;
	CGFloat previousZoom = session.zoomLevel;
	if(scalingOption != 0)
	{
		previousZoom = NSWidth([pageView imageBounds]) / [pageView combinedImageSizeForZoom: 1].width;
	}
	
	previousZoom -= 0.1;
	previousZoom = previousZoom < 0.1 ? 0.1 : previousZoom;
	session.zoomLevel = previousZoom;
	session.scaleOptions = 0;
	
	[pageView resizeView];
	[self refreshLoupePanel];
}

- (IBAction)zoomReset:(id)sender
{
	session.scaleOptions = 0;
	session.zoomLevel = 1.0;
	[pageView resizeView];
	[self refreshLoupePanel];
}


- (IBAction)rotate:(id)sender
{
	NSInteger segmentTag = [[sender cell] tagForSegment: [sender selectedSegment]];
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
	int currentRotation = session.rotation;
	currentRotation = currentRotation + 1 > 3 ? 0 : currentRotation + 1;
	session.rotation = currentRotation;
	[self resizeWindow];
	[self refreshLoupePanel];
}

- (IBAction)rotateLeft:(id)sender
{
	int currentRotation = session.rotation;
	currentRotation = currentRotation - 1 < 0 ? 3 : currentRotation - 1;
	session.rotation = currentRotation;
	[self resizeWindow];
	[self refreshLoupePanel];
}

- (IBAction)noRotation:(id)sender
{
	session.rotation = 0;
	[self resizeWindow];
	[self refreshLoupePanel];
}


- (IBAction)toggleLoupe:(id)sender
{
	BOOL loupe = session.loupe;
	loupe = !loupe;
	session.loupe = loupe;
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
	[jumpField setIntegerValue: [pageController selectionIndex] + 1];
	[self.window beginSheet:jumpPanel completionHandler:^(NSModalResponse returnCode) {
		[self closeSheet:returnCode];
	}];
}


- (IBAction)cancelJumpPanel:(id)sender
{
	[self.window endSheet: jumpPanel returnCode: NSModalResponseAbort];
}


- (IBAction)goToPage:(id)sender
{
	if([jumpField integerValue] != NSNotFound)
	{
		NSInteger index = [jumpField integerValue] < 1 ? 0 : [jumpField integerValue] - 1;
		[pageController setSelectionIndex: index];
	}
	
	[self.window endSheet: jumpPanel returnCode: NSModalResponseContinue];
}


- (IBAction)removePages:(id)sender
{
	pageSelectionInProgress = PageSelectionModeDelete;
	[self changeViewForSelection];
}


/*  Method that allows the user to select an icon for comic archives.
	Calls pageView and verifies that the images selected are from an
	archive. */
- (IBAction)setArchiveIcon:(id)sender
{
	pageSelectionInProgress = PageSelectionModeIcon;
	[self changeViewForSelection];
}


/*	Saves the selected page to a user specified location. */
- (IBAction)extractPage:(id)sender
{
	pageSelectionInProgress = PageSelectionModeExtract;
	[self changeViewForSelection];
}


- (BOOL)pageSelectionCanCrop
{
	return (pageSelectionInProgress == PageSelectionModeIcon);
}


/* Used by all of the page selection methods to make both pages visible.  Also adds a small
	gutter around the images for cropping. */
- (void)changeViewForSelection
{
	savedZoom = session.zoomLevel;
	[pageScrollView setHasVerticalScroller: NO];
	[pageScrollView setHasHorizontalScroller: NO];
	[self refreshLoupePanel];
	NSSize imageSize = [pageView combinedImageSizeForZoom: 1];
	NSSize scrollerBounds = [[pageView enclosingScrollView] bounds].size;
	scrollerBounds.height -= 20;
	scrollerBounds.width -= 20;
	CGFloat factor;
	if(imageSize.width / imageSize.height > scrollerBounds.width / scrollerBounds.height)
	{
		factor = scrollerBounds.width / imageSize.width;
	}
	else
	{
		factor = scrollerBounds.height / imageSize.height;
	}
	
	session.zoomLevel = factor;
	[pageView resizeView];
}


- (BOOL)canSelectPageIndex:(NSInteger)selection
{
	NSUInteger index = [pageController selectionIndex];
	index += selection;
	TSSTPage * selectedPage = [pageController arrangedObjects][index];
	TSSTManagedGroup * selectedGroup = selectedPage.group;
	/* Makes sure that the group is both an archive and not nested */
	if([selectedGroup class] == [TSSTManagedArchive class] &&
	   selectedGroup == [selectedGroup topLevelGroup] &&
	   !selectedPage.text)
	{
		return YES;
	}
	
	return NO;
}


- (BOOL)pageSelectionInProgress
{
	return (pageSelectionInProgress != PageSelectionModeNone);
}


- (void)cancelPageSelection
{
	session.zoomLevel = savedZoom;
	pageSelectionInProgress = PageSelectionModeNone;
	[self scaleToWindow];
}


- (void)selectedPage:(NSInteger)selection withCropRect:(NSRect)cropRect
{
	switch (pageSelectionInProgress)
	{
		case PageSelectionModeIcon:
			[self setIconWithSelection: selection andCropRect: cropRect];
			break;
		case PageSelectionModeDelete:
			[self deletePageWithSelection: selection];
			break;
		case PageSelectionModeExtract:
			[self extractPageWithSelection: selection];
			break;
		default:
			break;
	}
	
	session.zoomLevel = savedZoom;
	pageSelectionInProgress = PageSelectionModeNone;
	[self scaleToWindow];
}


- (void)deletePageWithSelection:(NSInteger)selection
{
	if(selection != -1)
	{
		NSUInteger index = [pageController selectionIndex];
		index += selection;
		TSSTPage * selectedPage = [pageController arrangedObjects][index];
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
		NSUInteger index = [pageController selectionIndex];
		index += selection;
		TSSTPage * selectedPage = [pageController arrangedObjects][index];
		
		NSSavePanel * savePanel = [NSSavePanel savePanel];
		[savePanel setTitle: NSLocalizedString(@"Extract Page", @"")];
		[savePanel setPrompt: NSLocalizedString(@"Extract", @"")];
		[savePanel setNameFieldStringValue:[selectedPage name]];
		if(NSModalResponseOK == [savePanel runModal])
		{
			[[selectedPage pageData] writeToFile: [[savePanel URL] path] atomically: YES];
		}
	}
}


- (void)setIconWithSelection:(NSInteger)selection andCropRect:(NSRect)cropRect
{
	if(selection != -1)
	{
		NSUInteger index = [pageController selectionIndex];
		index += selection;
		TSSTPage * selectedPage = [pageController arrangedObjects][index];
		TSSTManagedGroup * selectedGroup = selectedPage.group;
		/* Makes sure that the group is both an archive and not nested */
		if([selectedGroup isKindOfClass:[TSSTManagedArchive class]] &&
		   selectedGroup == [selectedGroup topLevelGroup] &&
		   !selectedPage.text)
		{
			NSString * archivePath = [selectedGroup.path stringByStandardizingPath];
			if([(TSSTManagedArchive *)selectedGroup quicklookCompatible])
			{
				NSInteger coverIndex = [selectedPage.index integerValue];
				NSString * coverName = [(XADArchive *)[selectedGroup instance] nameOfEntry: coverIndex];
				[UKXattrMetadataStore setString: coverName
										 forKey: SCQuickLookCoverName
										 atPath: archivePath
								   traverseLink: NO
										  error: nil];
				[UKXattrMetadataStore setString: NSStringFromRect(cropRect)
										 forKey: SCQuickLookCoverRect
										 atPath: archivePath
								   traverseLink: NO
										  error: nil];
				
				if(![[NSUserDefaults standardUserDefaults] boolForKey: TSSTPreserveModDate])
				{
					[NSTask launchedTaskWithLaunchPath: @"/usr/bin/touch"
											 arguments: @[archivePath]];
				}
			}
			else
			{
				NSRect drawRect = NSMakeRect(0, 0, 496, 496);
				NSImage * iconImage = [[NSImage alloc] initWithSize: drawRect.size];
				cropRect.size = NSEqualSizes(cropRect.size, NSZeroSize) ? NSMakeSize([[selectedPage valueForKey: @"width"] doubleValue], [[selectedPage valueForKey: @"height"] doubleValue]) : cropRect.size;
				drawRect = rectWithSizeCenteredInRect( cropRect.size, drawRect);
				
				[iconImage lockFocus];
				[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
				[[selectedPage pageImage] drawInRect: drawRect fromRect: cropRect operation: NSCompositingOperationSourceOver fraction: 1];
				[iconImage unlockFocus];
				
				NSImage * shadowImage = [[NSImage alloc] initWithSize: NSMakeSize(512, 512)];
				
				NSShadow * thumbShadow = [NSShadow new];
				[thumbShadow setShadowOffset: NSMakeSize(0.0, -8.0)];
				[thumbShadow setShadowBlurRadius: 25.0];
				[thumbShadow setShadowColor: [NSColor colorWithCalibratedWhite: 0.2 alpha: 1.0]];
				
				[shadowImage lockFocus];
				[thumbShadow set];
				[iconImage drawInRect: NSMakeRect(16, 16, 496, 496) fromRect: NSZeroRect operation: NSCompositingOperationSourceOver fraction: 1];
				[shadowImage unlockFocus];
				
				[[NSWorkspace sharedWorkspace] setIcon: shadowImage forFile: archivePath options: 0];
			}
		}
	}
	
	session.zoomLevel = savedZoom;
}


- (void)closeSheet:(NSInteger)code
{
	[jumpPanel close];
}


#pragma mark - Convenience Methods


- (void)hideCursor
{
	mouseMovedTimer = nil;

	if([[self window] isFullscreen])
	{
		[NSCursor setHiddenUntilMouseMoves: YES];
	}
}


- (void)restoreSession
{
	[self changeViewImages];
	[self scaleToWindow];
	[self adjustStatusBar];
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	NSInteger loupeDiameter = [defaults integerForKey: TSSTLoupeDiameter];
	[loupeWindow setFrame:NSMakeRect(0,0, loupeDiameter, loupeDiameter) display: NO];
	NSColor * color = [NSKeyedUnarchiver unarchiveObjectWithData: [defaults valueForKey: TSSTBackgroundColor]];
	[pageScrollView setBackgroundColor: color];
	[pageView setRotation: session.rotation];
	NSValue * positionValue;
	NSData * posData = [session valueForKey: @"position"];
	
	if(posData)
	{
		positionValue = [NSKeyedUnarchiver unarchiveObjectWithData: posData];
		if (!positionValue) {
			positionValue = [NSUnarchiver unarchiveObjectWithData: posData];
		}
		[[self window] setFrame: [positionValue rectValue] display: NO];
		NSData * scrollData = session.scrollPosition;
		if(scrollData)
		{
			[self setShouldCascadeWindows: NO];
			positionValue = [NSKeyedUnarchiver unarchiveObjectWithData: scrollData];
			if (!positionValue) {
				positionValue = [NSUnarchiver unarchiveObjectWithData: scrollData];
			}
			[pageView scrollPoint: [positionValue pointValue]];
		}
	}
	else
	{
		newSession = YES;
		[self setShouldCascadeWindows: YES];
		
		if (![[self window] isZoomed])
		{
			[[self window] zoom: self];
		} else {
			NSLog(@"Window is already zoomed – zoom not toggled");
		}
		
		[pageView correctViewPoint];
	}
}


- (void)changeViewImages
{
	NSUInteger count = [[pageController arrangedObjects] count];
	NSUInteger index = [pageController selectionIndex];
	TSSTPage * pageOne = [pageController arrangedObjects][index];
	TSSTPage * pageTwo = (index + 1) < count ? [pageController arrangedObjects][(index + 1)] : nil;
	NSString * titleString = pageOne.name;
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	
	BOOL currentAllowed = ![pageOne shouldDisplayAlone] &&
	!(index == 0 && [defaults boolForKey: TSSTLonelyFirstPage]);
	
	if(currentAllowed && session.twoPageSpread && pageTwo && ![pageTwo shouldDisplayAlone])
	{
		if(session.pageOrder)
		{
			titleString = [NSString stringWithFormat:@"%@ %@", titleString, pageTwo.name];
		}
		else
		{
			titleString = [NSString stringWithFormat:@"%@ %@", pageTwo.name, titleString];
		}
	}
	else
	{
		pageTwo = nil;
	}
	
	NSURL *representationURL = pageOne.group ? [pageOne valueForKeyPath: @"group.topLevelGroup.fileURL"] : [NSURL fileURLWithPath:pageOne.imagePath];
	[[self window] setRepresentedURL: representationURL];
	
	NSString *fileName = nil;
	[representationURL getResourceValue:&fileName forKey:NSURLLocalizedNameKey error:NULL];
	if (fileName != nil && pageOne.group != nil) {
		if (pageOne.group != nil && pageTwo.group != nil) {
			NSURL *page2URL = [pageTwo valueForKeyPath: @"group.topLevelGroup.fileURL"];
			BOOL bothAreGood = YES;
			BOOL theSame = NO;
			id dat1, dat2;
			
			if (![representationURL getResourceValue:&dat1 forKey:NSURLFileResourceIdentifierKey error:NULL]) {
				bothAreGood = NO;
			} else if (![page2URL getResourceValue:&dat2 forKey:NSURLFileResourceIdentifierKey error:NULL]) {
				bothAreGood = NO;
			}
			if (bothAreGood) {
				theSame = [dat1 isEqual:dat2];
			}
			if (theSame) {
				titleString = [NSString stringWithFormat:@"%@ — %@", fileName, titleString];
			}
		} else {
			titleString = [NSString stringWithFormat:@"%@ — %@", fileName, titleString];
		}
	}
	self.pageNames = titleString;
	[pageView setFirstPage: pageOne.pageImage secondPageImage: pageTwo.pageImage];
	
	[self scaleToWindow];
	[pageView correctViewPoint];
	[self refreshLoupePanel];
}


- (void)resizeWindow
{
    NSRect allowedRect;
    NSRect zoomFrame;
    NSRect frame;
    if([[self window] isFullscreen])
    {
        allowedRect = [[[self window] screen] frame];
        [[self window] setFrame: allowedRect display: YES animate: NO];
    }
    else if([[NSUserDefaults standardUserDefaults] boolForKey: TSSTWindowAutoResize])
    {
        allowedRect = [[[self window] screen] visibleFrame];
		frame = [[self window] frame];
		allowedRect = NSMakeRect(frame.origin.x, NSMinY(allowedRect),
								 NSMaxX(allowedRect) - NSMinX(frame),
								 NSMaxY(frame) - NSMinY(allowedRect));
        zoomFrame = [self optimalPageViewRectForRect: allowedRect];
        [[self window] setFrame: zoomFrame display: YES animate: NO];
    }
}


- (void)scaleToWindow
{
    BOOL hasVert = NO;
    BOOL hasHor = NO;
	int scaling = session.scaleOptions;
	
	if(pageSelectionInProgress || ![[NSUserDefaults standardUserDefaults] boolForKey: TSSTScrollersVisible])
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
        session.zoomLevel = 1.0;
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
        session.zoomLevel = 1.0;
		break;
	}
	
    [pageScrollView setHasVerticalScroller: hasVert];
    [pageScrollView setHasHorizontalScroller: hasHor];
	
	if(pageSelectionInProgress == PageSelectionModeNone)
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
    BOOL statusBar = [defaults boolForKey: TSSTStatusbarVisible];
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


- (void)nextPage
{
    if(!session.twoPageSpread)
    {
        [pageController selectNext: self];
        return;
    }
	
    NSUInteger numberOfImages = [[pageController arrangedObjects] count];
	NSUInteger selectionIndex = [pageController selectionIndex];
	if((selectionIndex + 1) >= numberOfImages)
	{
		return;
	}
	
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	BOOL current = ![[pageController arrangedObjects][selectionIndex] shouldDisplayAlone] &&
        !(selectionIndex == 0 &&[defaults boolForKey: TSSTLonelyFirstPage]);
	BOOL next = ![[pageController arrangedObjects][(selectionIndex + 1)] shouldDisplayAlone];
	
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


- (void)previousPage
{
    if(!session.twoPageSpread)
    {
        [pageController selectPrevious: self];
        return;
    }
	
	NSInteger selectionIndex = [pageController selectionIndex];
	if((selectionIndex - 2) >= 0)
	{
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        
        BOOL previousPage = ![[pageController arrangedObjects][(selectionIndex - 1)] shouldDisplayAlone];
		BOOL pageBeforeLast = ![[pageController arrangedObjects][(selectionIndex - 2)] shouldDisplayAlone] &&
            !((selectionIndex - 2) == 0 && [defaults boolForKey: TSSTLonelyFirstPage]);
        
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


- (void)updateSessionObject
{
    if(![[self window] isFullscreen])
    {
        NSValue * postionValue = [NSValue valueWithRect: [[self window] frame]];
        NSData * posData = [NSKeyedArchiver archivedDataWithRootObject: postionValue];
        session.position = posData;
        
        postionValue = [NSValue valueWithPoint: [[pageView enclosingScrollView] documentVisibleRect].origin];
        posData = [NSKeyedArchiver archivedDataWithRootObject: postionValue];
        session.scrollPosition = posData;
    }
    else
    {
        session.scrollPosition = nil;
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
    else if([[self window] isFullscreen])
    {
        [[self window] toggleFullScreen: self];
    }
	else if(session.loupe)
	{
        session.loupe = NO;
	}
}


- (void)killAllOptionalUIElements
{
    if([[self window] isFullscreen])
    {
        [[self window] toggleFullScreen: self];
    }
    session.loupe = NO;
    [self refreshLoupePanel];
	[exposeBezel removeChildWindow: thumbnailPanel];
	[thumbnailPanel orderOut: self];
	[exposeBezel orderOut: self];
}


#pragma mark -
#pragma mark Binding Methods

@synthesize session;


- (NSManagedObjectContext *)managedObjectContext
{
    return [(SimpleComicAppDelegate *)[NSApp delegate] managedObjectContext];
}


- (BOOL)canTurnPageLeft
{
	if(session.pageOrder)
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
	if(session.pageOrder)
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
	NSInteger selectionIndex = [pageController selectionIndex];
	if([pageController selectionIndex] >= ([[pageController content] count] - 1))
	{
		return NO;
	}
	
	if((selectionIndex + 1) == ([[pageController content] count] - 1) && session.twoPageSpread)
	{
		NSArray * arrangedPages = [pageController arrangedObjects];
		BOOL displayCurrentAlone = [arrangedPages[selectionIndex] shouldDisplayAlone];
		BOOL displayNextAlone = [arrangedPages[selectionIndex + 1] shouldDisplayAlone];

		if (!displayCurrentAlone && !displayNextAlone)
        {
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
    if([menuItem action] == @selector(toggleFullScreen:))
    {
        state = [[self window] isFullscreen] ? NSControlStateValueOn : NSControlStateValueOff;
        [menuItem setState: state];
    }
    else if([menuItem action] == @selector(changeTwoPage:))
    {
        state = session.twoPageSpread ? NSControlStateValueOn : NSControlStateValueOff;
        [menuItem setState: state];
    }
    else if([menuItem action] == @selector(changePageOrder:))
    {
        if(session.pageOrder)
        {
            [menuItem setTitle: NSLocalizedString(@"Right to Left", @"Right to left page order menu item text")];
        }
        else
        {
            [menuItem setTitle: NSLocalizedString(@"Left to Right", @"Left to right page order menu item text")];
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
		valid = !session.rotation;
	}
	else if ([menuItem action] == @selector(extractPage:))
	{
		valid = !session.rotation;
	}
	else if ([menuItem action] == @selector(removePages:))
	{
		valid = !session.rotation;
	}
    else if([menuItem tag] == 400)
    {
        state = session.scaleOptions == 0 ? NSControlStateValueOn : NSControlStateValueOff;
        [menuItem setState: state];
    }
    else if([menuItem tag] == 401)
    {
        state = session.scaleOptions == 1 ? NSControlStateValueOn : NSControlStateValueOff;
        [menuItem setState: state];
    }
    else if([menuItem tag] == 402)
    {
        state = session.scaleOptions == 2 ? NSControlStateValueOn : NSControlStateValueOff;
        [menuItem setState: state];
    }
	
    return valid;
}


#pragma mark -
#pragma mark Delegates


- (BOOL)control:(NSTextField *)control didFailToFormatString:(NSString *)string errorDescription:(NSString *)error
{
	NSInteger pageNumber = [string integerValue];
	if(pageNumber > [[pageController arrangedObjects] count])
	{
		[jumpField setIntegerValue: [[pageController arrangedObjects] count]];
	}
	else
	{
		NSBeep();
		[jumpField setIntegerValue: [pageController selectionIndex] + 1];
	}
	
	return YES;
}


- (void)prepareToEnd
{
	[[self window] setAcceptsMouseMovedEvents: NO];
	[mouseMovedTimer invalidate];
	mouseMovedTimer = nil;
    [NSCursor unhide];
    [NSApp setPresentationOptions: NSApplicationPresentationDefault];
	
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
    if([aNotification object] == [self window])
    {
        [NSApp setPresentationOptions: NSApplicationPresentationDefault];
		if(session.loupe)
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
}


- (void)windowDidResize:(NSNotification *)aNotification
{
	BOOL statusBar;
    if([aNotification object] == [self window])
    {
		[[infoWindow parentWindow] removeChildWindow: infoWindow];
        [infoWindow orderOut: self];
		
        statusBar = [[NSUserDefaults standardUserDefaults] boolForKey: TSSTStatusbarVisible];
		
        if(statusBar)
        {
            NSPoint mouse = [NSEvent mouseLocation];
            NSRect point = NSMakeRect(mouse.x, mouse.y, 0, 0);
            NSPoint mouseLocation = [[self window] convertRectFromScreen: point].origin;

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
	the nice little plus button in the upper left of the window. */
- (NSRect)windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame
{
	if(sender == [self window])
	{
		defaultFrame = [self optimalPageViewRectForRect: defaultFrame];
	}
	
	return defaultFrame;
}

- (NSRect)optimalPageViewRectForRect:(NSRect)boundingRect
{
	NSSize maxImageSize = [pageView combinedImageSizeForZoom: session.zoomLevel];
	CGFloat vertOffset = [[self window] contentBorderThicknessForEdge: NSMinYEdge] + [[self window] toolbarHeight];
	if([pageScrollView hasHorizontalScroller] && pageScrollView.horizontalScroller.scrollerStyle == NSScrollerStyleLegacy)
	{
		vertOffset += NSHeight([[pageScrollView horizontalScroller] frame]);
	}
	CGFloat horOffset = [pageScrollView hasVerticalScroller] && pageScrollView.verticalScroller.scrollerStyle == NSScrollerStyleLegacy ? [NSScroller scrollerWidthForControlSize:pageScrollView.verticalScroller.controlSize scrollerStyle:pageScrollView.verticalScroller.scrollerStyle] : 0;
	NSSize minSize = [[self window] minSize];
	NSRect correctedFrame = boundingRect;
	correctedFrame.size.width = MAX(NSWidth(correctedFrame), minSize.width);
	correctedFrame.size.height = MAX(NSHeight(correctedFrame), minSize.height);
	correctedFrame.size.width -= horOffset;
	correctedFrame.size.height -= vertOffset;
	NSSize newSize;
	if(session.scaleOptions == 1 && ![self currentPageIsText])
	{
		CGFloat scale;
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
	
	newSize.width += horOffset;
	newSize.height += vertOffset;
	
	newSize.width = newSize.width < minSize.width ? minSize.width : newSize.width;
	newSize.height = newSize.height < minSize.height ? minSize.height : newSize.height;
	
	NSRect windowFrame = NSMakeRect(NSMinX(boundingRect), NSMaxY(boundingRect) - newSize.height, newSize.width, newSize.height);
	return windowFrame;
}

- (void)resizeView
{
	[pageView resizeView];
}

- (BOOL)currentPageIsText
{
	TSSTPage * page = [pageController selectedObjects].firstObject;
	return page.text;
}


- (void)toolbarWillAddItem:(NSNotification *)notification
{
	NSToolbarItem * item = [notification userInfo][@"item"];
	
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
}


#pragma Fullscreen Delegate Methods

- (NSApplicationPresentationOptions)window:(NSWindow *)window willUseFullScreenPresentationOptions:(NSApplicationPresentationOptions)proposedOptions
{
	if([[self window] isEqual: window])
	{
		if (![[NSUserDefaults standardUserDefaults] boolForKey: TSSTFullscreenToolbar])
		{
			return NSApplicationPresentationAutoHideDock |
			NSApplicationPresentationAutoHideMenuBar |
			NSApplicationPresentationAutoHideToolbar |
			NSApplicationPresentationFullScreen;
		}
		else
		{
			return NSApplicationPresentationAutoHideDock |
			NSApplicationPresentationAutoHideMenuBar |
			NSApplicationPresentationFullScreen;
		}
	}
	
	return NSApplicationPresentationDefault;
}

- (void)windowWillEnterFullScreen:(NSNotification *)notification
{
}

- (void)windowDidEnterFullScreen:(NSNotification *)notification
{
//    [self resizeWindow];
	[self refreshLoupePanel];
}

- (void)windowDidExitFullScreen:(NSNotification *)notification
{
	[self resizeWindow];
}

@end
