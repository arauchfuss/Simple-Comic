//
//  DTSessionWindow.h
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 4/15/17.
//
//

#import <Cocoa/Cocoa.h>
@class TSSTManagedSession;
@class DTPageArrayController;

/*  Handles the following functionality.
    Menu validation
    Core Animation layout
    Session Management/Core Data setup
 
    Once things are more stable the Core Animation stuff
    will go in a view controller.
 */
@interface DTSessionWindow : NSWindowController <CALayerDelegate> {
    IBOutlet NSView * pageView; // Layer backed, no direct drawing.
    IBOutlet DTPageArrayController * pageController; // Full of TSSTPage objects
    
    CALayer * firstPage;
    CALayer * secondPage;
    CGSize firstPageSize;
    CGSize secondPageSize;
    
    CALayer * oldPageOne;
    CALayer * oldPageTwo;

}

// Properties used by the ArrayController
@property (readonly) TSSTManagedSession * session;
@property (readonly) NSManagedObjectContext * managedObjectContext;
@property (retain) NSArray * pageSortDescriptor;
@property (assign) int pageTurn; // Keeps track of page turn status for animations.

// Must use this method, a straight init will cause everything to break.
- (id)initWithSession:(TSSTManagedSession *)newSession;
// Used for saving state.
- (void)updateSessionObject;
// Initial layer setup no page layers added.
- (void)setupPageLayers;
// Adds page layers to view but does not do any layout.
- (void)updatePages;

- (NSRect)optimalPageViewRectForRect:(NSRect)boundingRect;

@end
