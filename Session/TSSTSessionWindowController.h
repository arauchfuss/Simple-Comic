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
 
    TSSTSessionWindowController.h
*/


#import <Cocoa/Cocoa.h>
#import "TSSTPageView.h"

@class TSSTPageView;
@class TSSTKeyWindow;
@class TSSTPage;
@class DTPolishedProgressBar;
@class TSSTInfoWindow;
@class TSSTImageView;
@class TSSTManagedSession;

enum PageSelectionMode {
	None,
	Icon,
	Delete,
	Extract
};


/*	This class deals with an unholy crapload of functionality
	- First and most importantly it controls the navigation 
		within a given session's pages.  This includes figuring 
		out whether or not two pages should be layed out side by side.
	- It handles almost all actions that affect its given session.
		Event handling is mainly taken care of by the page view class.
	- As the session window controller it handles the transition from
		windowed to fullscreen mode.
	- Mouse moved events are handled here. Which results in the following
		- Handles the movement and positioning of the page loupe.
		- Handles the layout of the info window 
			when the user scrubs the progress bar.
*/
@interface TSSTSessionWindowController : NSWindowController <NSTextFieldDelegate, DTPageSelection_Protocol>
{
    /* Controller for all of the page entities related to the session object */
    IBOutlet NSArrayController * pageController;
    
    /* Where the pages are composited.  Handles all of the drawing logic */
    IBOutlet TSSTPageView  * pageView;
	/* There is an outlet to this so that the visibility of the 
		scrollers can be manually controlled. */
    IBOutlet NSScrollView  * pageScrollView;
    
	/*	Allows the user to jump to a specific page via a small slide in modal dialog. */
	IBOutlet NSPanel	   * jumpPanel;
	IBOutlet NSTextField   * jumpField;
	
    /* Progress bar */
    IBOutlet DTPolishedProgressBar * progressBar;
	
	/* Page info window with caret. */
    IBOutlet TSSTInfoWindow     * infoWindow;
    IBOutlet NSImageView        * infoPicture;

    /* Localized image zoom loupe elements */
    IBOutlet TSSTInfoWindow * loupeWindow;
    IBOutlet NSImageView    * zoomView;
	
	/* Panel and view for the page expose method */
    IBOutlet NSPanel * exposeBezel;
    IBOutlet NSView * exposeView;
	IBOutlet TSSTInfoWindow * thumbnailPanel;
	
	/* The session object used to maintain settings */
    TSSTManagedSession * session;
    
    /* This var is bound to the session window name */
    NSString * pageNames;
    NSInteger pageTurn;
	
	/* Exactly what it sounds like */
	NSArray * pageSortDescriptor;
	
	/* Manages the cursor hiding while in fullscreen */
	NSTimer * mouseMovedTimer;
	
	BOOL newSession;
	
	enum PageSelectionMode pageSelectionInProgress;
	float savedZoom;
}

@property (retain) NSArray * pageSortDescriptor;
@property (assign) NSInteger pageTurn;
@property (retain) NSString * pageNames;

- (instancetype)initWithSession:(TSSTManagedSession *)aSession NS_DESIGNATED_INITIALIZER;

// View Actions
- (IBAction)changePageOrder:(id)sender;
/* Toggles between two page spread and single page */
- (IBAction)changeTwoPage:(id)sender;
/* Action that changes the view scaling between the three modes */
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
- (IBAction)turnPage:(id)sender;
- (IBAction)pageRight:(id)sender;
- (IBAction)pageLeft:(id)sender;
- (IBAction)shiftPageRight:(id)sender;
- (IBAction)shiftPageLeft:(id)sender;
- (IBAction)skipRight:(id)sender;
- (IBAction)skipLeft:(id)sender;
- (IBAction)firstPage:(id)sender;
- (IBAction)lastPage:(id)sender;

- (IBAction)launchJumpPanel:(id)sender;
- (IBAction)cancelJumpPanel:(id)sender;
- (IBAction)goToPage:(id)sender;

- (IBAction)removePages:(id)sender;
- (IBAction)setArchiveIcon:(id)sender;
- (IBAction)extractPage:(id)sender;

- (IBAction)togglePageExpose:(id)sender;

- (void)setIconWithSelection:(NSInteger)selection andCropRect:(NSRect)cropRect;
- (void)deletePageWithSelection:(NSInteger)selection;
- (void)extractPageWithSelection:(NSInteger)selection;
- (void)changeViewForSelection;

/* Used by the jump to page method */
- (void)closeSheet:(NSInteger)code;

- (NSImage *)imageForPageAtIndex:(NSInteger)index;
- (NSString *)nameForPageAtIndex:(NSInteger)index;

- (void)restoreSession;
- (void)prepareToEnd;


- (void)refreshLoupePanel;
- (void)infoPanelSetupAtPoint:(NSPoint)point;

- (void)handleMouseDragged:(NSNotification*)notification;

- (void)resizeWindow;
- (void)resizeView;
- (void)scaleToWindow;
- (void)adjustStatusBar;
- (void)changeViewImages;

- (void)nextPage;
- (void)previousPage;
- (void)updateSessionObject;
@property (readonly) BOOL currentPageIsText;

/* Bindings */
@property (readonly) BOOL canTurnPreviousPage;
@property (readonly) BOOL canTurnPageNext;
@property (readonly) BOOL canTurnPageLeft;
@property (readonly) BOOL canTurnPageRight;


@property (readonly, strong) TSSTManagedSession *session;
@property (readonly, strong) NSManagedObjectContext *managedObjectContext;
- (void)toolbarWillAddItem:(NSNotification *)notification;


/*	Methods that kill page expose, the loupe, and fullscreen.
	In that order. */
- (void)killAllOptionalUIElements;
- (void)killTopOptionalUIElement;

- (NSRect)optimalPageViewRectForRect:(NSRect)boundingRect;

@end

