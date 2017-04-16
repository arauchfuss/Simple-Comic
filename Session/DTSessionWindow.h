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

@interface DTSessionWindow : NSWindowController <CALayerDelegate> {
    IBOutlet NSView * pageView;
    IBOutlet DTPageArrayController * pageController;
}

@property (readonly) TSSTManagedSession * session;
@property (readonly) NSManagedObjectContext * managedObjectContext;
@property (retain) NSArray * pageSortDescriptor;


- (id)initWithSession:(TSSTManagedSession *)newSession;

- (void)setupPageLayers;

@end
