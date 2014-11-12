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
	TSSTPageView.h
 
	Composites one or two images to the screen, making sure that they
	are horizontally alligned.
	None of the logic involving the aspect ratios of the images is
	in this class.
*/


#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
@class TSSTSessionWindowController;

typedef struct {
	float left;
	float right;
	float up;
	float down;
} direction;

@protocol DTPageSelection_Protocol

- (BOOL)pageSelectionInProgress;
- (BOOL)pageSelectionCanCrop;
- (void)selectedPage:(NSInteger)index withCropRect:(NSRect)crop;
- (BOOL)canSelectPageIndex:(NSInteger)index;
- (void)cancelPageSelection;

@end

@protocol DTPageLayout_Protocol

- (NSInteger)pageScaling;
- (BOOL)leftToRightOrder;
- (BOOL)singlePageLayout;

@end

@protocol DTPageSource_Protocol

- (NSImage *)pageOne;
- (NSImage *)pageTwo;

@end




@interface TSSTPageView : NSView
{
    NSRect imageBounds;
	NSRect firstPageRect;
	NSRect secondPageRect;
	NSImage	* firstPageImage;
	NSImage	* secondPageImage;
    
    int scrollKeys;			// Stores which arrow keys are currently depressed this enables multi axis keyboard scrolling.
    NSTimer * scrollTimer;	// Timer that fires in between each keydown event to smooth out the scrolling.
	NSDate * interfaceDelay;
	
    NSInteger rotation;
	
    TSSTSessionWindowController * sessionController;
	
	direction scrollwheel;
    
	// This controls the drawing of the accepting drag-drop border highlighting 
    BOOL acceptingDrag;
	
	/*	While page selection is in progress this method has a value of 1 or 2.
		The selection number coresponds to a highlighted page. */
	int pageSelection;
	/* This is the rect describing the users page selection. */
	NSRect cropRect;
}

@property (nonatomic, assign) NSInteger rotation;
@property (assign)IBOutlet TSSTSessionWindowController * sessionController;


/*  This is where it all begins sets the two pages.  
    Starts any animations
    Calls resize view
    Calls correctViewPoint */
- (void)setFirstPage:(NSImage *)first secondPageImage:(NSImage *)second;


/*  Finds the size of the pages that are to be renedered.
    This includes minor scaling to equalize the height of facing pages. */
- (NSSize)combinedImageSizeForZoom:(float)level;


/*  If the view are is larger than the display area 
    then drag scrolling is available. */
@property (readonly) BOOL dragIsPossible;


/*  This is used by the image loupe.  Grabs the portion of the pages
    displayed that fall within "rect." The origin of the argument
    is centered instead of at the bottom left. */
-(NSImage *)imageInRect:(NSRect)rect;


/*  This is the actual rectangle within which the pages are rendered.
    Handy to know for various reasons. */
@property (readonly) NSRect imageBounds;


/* This method scrolls the views so that the proper 
    corner is displayed if the pages rendered are 
    larger than the display area. */
- (void)correctViewPoint;


/*  Resizes the view based on the current scaling method and the 
    selected images. */
- (void)resizeView;

/* Used to find the click area for page selection */
- (NSRect)pageSelectionRect:(NSInteger)selection;

/*	Concatinates an affine transform to the context.
	This is what enables the page rotation. */
- (void)rotationTransformWithFrame:(NSRect)rect;

@property (readonly) BOOL horizontalScrollIsPossible;
@property (readonly) BOOL verticalScrollIsPossible;

// Timers
- (void)startAnimationForImage:(NSImage *)image;
- (void)animateImage:(NSTimer *)timer;

/*	My rather crappy smooth scrolling timer.
	It does allow for multi axis keyboard scrolling though which is pretty cool. */
- (void)scroll:(NSTimer *)timer;

- (void)pageUp;
- (void)pageDown;

@property (readonly) NSRect imageCropRectangle;

@end

