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
 
    TSSTSessionWindowController.h
*/


#import <Cocoa/Cocoa.h>


@class TSSTPageView;
@class TSSTKeyWindow;
@class TSSTPage;
@class TSSTCRTProgressBar;
@class TSSTInfoWindow;
@class TSSTImageView;
@class TSSTManagedSession;
@class TSSTFullscreenProgressBar;


/*	This class deals with an unholy crapload of functionality
	- First and most importantly it controlls the navigation 
		within a given session's pages.  This includes figuring 
		out whether or not two pages should be layed out side by side.
	- It handles almost all actions that affects its given session.
		event handling is mainly taken care of by the page view class.
	- As the session window controller it handles the transition from
		windowed to fullscreen mode.
	- Mouse moved events are handled here. Which results in the following
		- Handles the movement and positioning of the page loupe.
		- Handles the layout of the info window that is displayed 
			when the user scrubs the progress bar.
*/
@interface TSSTSessionWindowController : NSWindowController
{
    /* Controller for all of the page entities related to the session object */
    IBOutlet NSArrayController * pageController;
    
    /* Where the pages are composited.  Handles all of the drawing logic */
    IBOutlet TSSTPageView  * pageView;
	/* There is an outlet to this so that the visibility of the 
		scrollers can be manually controlled. */
    IBOutlet NSScrollView  * pageScrollView;
    /* When session goes into fullscreen mode the scrollview and its
		pageview sub-view are moved into this window. */
    IBOutlet NSWindow * fullscreenWindow;
    
    /* Fullscreen control bezel. */
    IBOutlet NSWindow      * bezelWindow;
    
	/*	Allows the user to jump to a specific page via a small slide in modal dialog. */
	IBOutlet NSPanel	   * jumpPanel;
	IBOutlet NSTextField   * jumpField;
	
    /* Progress bar */
    IBOutlet TSSTCRTProgressBar * progressBar;
	IBOutlet TSSTFullscreenProgressBar * fullscreenProgressBar;
	
	/* Page info window with caret. */
    IBOutlet TSSTInfoWindow     * infoWindow;
    IBOutlet NSImageView        * infoPicture;

    /* Localized image zoom loupe elements */
    IBOutlet TSSTInfoWindow * loupeWindow;
    IBOutlet NSImageView    * zoomView;
	
    IBOutlet NSPanel * exposeBezel;
    IBOutlet NSView * exposeView;
	IBOutlet TSSTInfoWindow * thumbnailPanel;
        
    TSSTManagedSession * session;
    
    NSViewAnimation * bezelAnimation;
    
    NSString * pageNames;
    NSInteger pageTurn;
	NSArray * pageSortDescriptor;
	
	NSTimer * mouseMovedTimer;
	
	BOOL closing;
}

@property (retain) NSArray * pageSortDescriptor;
@property (assign) NSInteger pageTurn;
@property (retain) NSString * pageNames;

- (id)initWithSession:(TSSTManagedSession *)aSession;

// View Actions
- (IBAction)changePageOrder:(id)sender;
- (IBAction)changeFullscreen:(id)sender;
- (IBAction)changeTwoPage:(id)sender;
- (IBAction)changeScaling:(id)sender;
- (IBAction)zoom:(id)sender;
- (IBAction)zoomIn:(id)sender;
- (IBAction)zoomOut:(id)sender;
- (IBAction)zoomReset:(id)sender;
- (IBAction)rotate:(id)sender;
- (IBAction)rotateRight:(id)sender;
- (IBAction)rotateLeft:(id)sender;
- (IBAction)noRotation:(id)sender;
- (IBAction)toggleLoupe:(id)sender;

// Selection Actions
- (IBAction)exportPage:(id)sender;
- (IBAction)removePages:(id)sender;
- (IBAction)turnPage:(id)sender;
- (IBAction)pageRight:(id)sender;
- (IBAction)pageLeft:(id)sender;
- (IBAction)shiftPageRight:(id)sender;
- (IBAction)shiftPageLeft:(id)sender;
- (IBAction)skipRight:(id)sender;
- (IBAction)skipLeft:(id)sender;
- (IBAction)firstPage:(id)sender;
- (IBAction)lastPage:(id)sender;
- (IBAction)togglePageExpose:(id)sender;
- (IBAction)goToPage:(id)sender;
- (IBAction)launchJumpPanel:(id)sender;
- (IBAction)cancleJumpPanel:(id)sender;
- (IBAction)setArchiveIcon:(id)sender;

//- (IBAction)addBookmark:(id)sender;
- (void)closeSheet:(int)code;

- (NSImage *)imageForPageAtIndex:(int)index;
- (NSString *)nameForPageAtIndex:(int)index;

- (void)refreshLoupePanel;
- (void)infoPanelSetupAtPoint:(NSPoint)point;
- (void)restoreSession;
- (void)scaleToWindow;
- (void)changeViewImages;
- (void)fullscreen;
//- (void)animateBezel;
- (void)adjustStatusBar;
- (void)resizeWindow;
- (void)prepareToEnd;

- (void)nextPage;
- (void)previousPage;
- (void)updateSessionObject;
- (float)toolbarHeight;


- (TSSTManagedSession *)session;
- (NSManagedObjectContext *)managedObjectContext;
- (void)killAllOptionalUIElements;
- (void)killTopOptionalUIElement;


@end

