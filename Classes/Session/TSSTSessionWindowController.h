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

    TSSTSessionWindowController.h
*/


#import <Cocoa/Cocoa.h>
#import "TSSTPageView.h"

@class TSSTPageView;
@class TSSTKeyWindow;
@class TSSTPage;
@class DTPolishedProgressBar;
@class TSSTInfoWindow;
@class TSSTManagedSession;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const TSSTMouseDragNotification;

typedef NS_ENUM(NSInteger, PageSelectionMode)  {
	PageSelectionModeNone,
	PageSelectionModeIcon,
	PageSelectionModeDelete,
	PageSelectionModeExtract
};


/*!	This class deals with an unholy crapload of functionality
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
@interface TSSTSessionWindowController : NSWindowController <NSTextFieldDelegate, DTPageSelectionProtocol, NSWindowDelegate>

/*! Controller for all of the page entities related to the session object */
@property (weak) IBOutlet NSArrayController * pageController;

/*! Where the pages are composited.  Handles all of the drawing logic */
@property (weak) IBOutlet TSSTPageView  * pageView;
/*! There is an outlet to this so that the visibility of the
 scrollers can be manually controlled. */
@property (weak) IBOutlet NSScrollView  * pageScrollView;

/*	Allows the user to jump to a specific page via a small slide in modal dialog. */
@property (weak) IBOutlet NSPanel	   * jumpPanel;
@property (weak) IBOutlet NSTextField   * jumpField;

/*! Progress bar */
@property (weak) IBOutlet DTPolishedProgressBar * progressBar;

/* Page info window with caret. */
@property (weak) IBOutlet TSSTInfoWindow     * infoWindow;
@property (weak) IBOutlet NSImageView        * infoPicture;

/* Localized image zoom loupe elements */
@property (weak) IBOutlet TSSTInfoWindow * loupeWindow;
@property (weak) IBOutlet NSImageView    * zoomView;

/* Panel and view for the page expose method */
@property (weak) IBOutlet NSPanel * exposeBezel;
@property (weak) IBOutlet NSView * exposeView;
@property (weak) IBOutlet TSSTInfoWindow * thumbnailPanel;

@property (copy) NSArray<NSSortDescriptor*> * pageSortDescriptor;
@property (assign) NSInteger pageTurn;
@property (copy) NSString * pageNames;

- (instancetype)initWithSession:(TSSTManagedSession *)aSession;

// View Actions
- (IBAction)changePageOrder:(nullable id)sender;
/*! Toggles between two page spread and single page */
- (IBAction)changeTwoPage:(nullable id)sender;
/*! Action that changes the view scaling between the three modes */
- (IBAction)changeScaling:(nullable id)sender;

- (IBAction)zoom:(nullable id)sender;
- (IBAction)zoomIn:(nullable id)sender;
- (IBAction)zoomOut:(nullable id)sender;
- (IBAction)zoomReset:(nullable id)sender;

- (IBAction)rotate:(nullable id)sender;
- (IBAction)rotateRight:(nullable id)sender;
- (IBAction)rotateLeft:(nullable id)sender;
- (IBAction)noRotation:(nullable id)sender;

- (IBAction)toggleLoupe:(nullable id)sender;

// Selection Actions
- (IBAction)turnPage:(nullable id)sender;
- (IBAction)pageRight:(nullable id)sender;
- (IBAction)pageLeft:(nullable id)sender;
- (IBAction)shiftPageRight:(nullable id)sender;
- (IBAction)shiftPageLeft:(nullable id)sender;
- (IBAction)skipRight:(nullable id)sender;
- (IBAction)skipLeft:(nullable id)sender;
- (IBAction)firstPage:(nullable id)sender;
- (IBAction)lastPage:(nullable id)sender;

- (IBAction)launchJumpPanel:(nullable id)sender;
- (IBAction)cancelJumpPanel:(nullable id)sender;
- (IBAction)goToPage:(nullable id)sender;

- (IBAction)removePages:(nullable id)sender;
- (IBAction)setArchiveIcon:(nullable id)sender;
- (IBAction)extractPage:(nullable id)sender;

- (IBAction)togglePageExpose:(nullable id)sender;

- (void)setIconWithSelection:(NSInteger)selection andCropRect:(NSRect)cropRect;
- (void)deletePageWithSelection:(NSInteger)selection;
- (void)extractPageWithSelection:(NSInteger)selection;
- (void)changeViewForSelection;

/*! Used by the jump to page method */
- (void)closeSheet:(NSInteger)code;

- (NSImage *)imageForPageAtIndex:(NSInteger)index;
- (NSString *)nameForPageAtIndex:(NSInteger)index;

/*!  When a session is launched this method is called.  It checks to see if the
 session was a saved session or one that is brand new.  If it was a saved
 session then all of the saved session information is passed to the window
 and view. */
- (void)restoreSession;

- (void)prepareToEnd;


- (void)refreshLoupePanel;
- (void)infoPanelSetupAtPoint:(NSPoint)point;

- (void)handleMouseDragged:(NSNotification*)notification;

- (void)resizeWindow;
- (void)resizeView;
- (void)scaleToWindow;
- (void)adjustStatusBar;

/*!  This method figures out which pages should be displayed in the view.
 To do so it looks at which page is currently selected as well as its aspect ratio
 and that of the next image */
- (void)changeViewImages;

/*! Selects the next non visible page.  Logic looks figures out which
 images are currently visible and then skips over them.
 */
- (void)nextPage;

/*! Selects the previous non visible page.  Logic looks figures out which
 images are currently visible and then skips over them.
 */
- (void)previousPage;

/*! This method is called in preparation for saving. */
- (void)updateSessionObject;

@property (readonly) BOOL currentPageIsText;

/* Bindings */
@property (readonly) BOOL canTurnPreviousPage;
@property (readonly) BOOL canTurnPageNext;
@property (readonly) BOOL canTurnPageLeft;
@property (readonly) BOOL canTurnPageRight;


//! The session object used to maintain settings
@property (readonly, strong) TSSTManagedSession *session;
@property (readonly, strong) NSManagedObjectContext *managedObjectContext;
- (void)toolbarWillAddItem:(NSNotification *)notification;


/*!	Methods that kill page expose, the loupe, and fullscreen.
	In that order. */
- (void)killAllOptionalUIElements;
- (void)killTopOptionalUIElement;

- (NSRect)optimalPageViewRectForRect:(NSRect)boundingRect;

@end

NS_ASSUME_NONNULL_END
