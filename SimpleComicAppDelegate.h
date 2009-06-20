/*	
	Copyright (c) 2006 Dancing Tortoise Software

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
	SimpleComicAppDelegate.h
*/


#import <Cocoa/Cocoa.h>


@class SS_PrefsController;
@class TSSTSessionWindowController;
@class TSSTManagedArchive;
@class TSSTManagedGroup;
@class TSSTManagedPDF;
@class TSSTManagedSession;
@class SUUpdater;


extern NSString * TSSTPageOrder;
extern NSString * TSSTPageZoomRate;
extern NSString * TSSTFullscreen;
extern NSString * TSSTSavedSelection;
extern NSString * TSSTThumbnailSize;
extern NSString * TSSTTwoPageSpread;
extern NSString * TSSTPageScaleOptions;
extern NSString * TSSTIgnoreDonation;
extern NSString * TSSTScrollPosition;
extern NSString * TSSTConstrainScale;
extern NSString * TSSTZoomLevel;
extern NSString * TSSTViewRotation;
extern NSString * TSSTBackgroundColor;
extern NSString * TSSTSessionRestore;
extern NSString * TSSTScrollersVisible;
extern NSString * TSSTAutoPageTurn;
extern NSString * TSSTWindowAutoResize;
extern NSString * TSSTLoupeDiameter;
extern NSString * TSSTLoupePower;
extern NSString * TSSTStatusbarVisible;
extern NSString * TSSTLonelyFirstPage;
extern NSString * TSSTNestedArchives;
extern NSString * TSSTUpdateSelection;


/*!
    This class is the application delegate.
    It handles the following:
 
    The Core Data store
    File loading
    Session mangement
    Session auto-save
    Archive password prompts during their loading
    Fallback archive encoding selection
*/
@interface SimpleComicAppDelegate : NSObject
{
/*  When opening encrypted zip or rar archives this panel is
    made visible as a modal so the user can enter a password. */
    IBOutlet NSPanel           * passwordPanel;
    IBOutlet NSSecureTextField * passwordField;
    
/*  This panel appears when the text encoding auto-detection fails */
    IBOutlet NSPanel           * encodingPanel;
    IBOutlet NSTextField       * encodingTestField;
    const char                 * encodingTestString;
    NSInteger					 encodingSelection;
    IBOutlet NSMenu            * encodingMenu;

    IBOutlet NSPanel * donationPanel;
	
	IBOutlet SUUpdater		   * updater;

/*  Core Data stuff. */
    NSManagedObjectModel		 * managedObjectModel;
    NSManagedObjectContext		 * managedObjectContext;
	NSPersistentStoreCoordinator * persistentStoreCoordinator;

/*  Window controller for preferences. */
    SS_PrefsController      * preferences;
    
/*  This is the array that maintains all of the session window managers. */
    NSMutableArray * sessions;
    
    BOOL      launchInProgress;
	NSArray	* launchFiles;
	
}



@property (assign) NSInteger encodingSelection;

/*  Convenience method for adding metadata to the core data store.
    Used by Simple Comic to keep track of store versioning. */
+ (void)setMetadata:(NSString *)value forKey:(NSString *)key onStoreWithURL:(NSURL *)url managedBy:(NSPersistentStoreCoordinator *)coordinator;

/*  Core Data methods, slightly altered boilerplate. */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;
- (NSString *)applicationSupportFolder;

- (BOOL)saveContext;


/*  Creates a new Session object based on user prefs and then 
    passes the files array to addFiles:toSesion: */
- (TSSTManagedSession *)newSessionWithFiles:(NSArray *)files;

/*  This method is called every time an existing session needs
    to be made  visible to a user. */
- (void)windowForSession:(TSSTManagedSession *)session;

/*  This is what TSSTSessionWindowController instances call when they
    want to close. Removes them from the session array. */
- (void)endSession:(TSSTSessionWindowController *)manager;

/*  This method is called at launch, it iterates through all of the saved
    sessions calling windowForSession: for each in turn. */
- (void)sessionRelaunch;
    
/*  This method adds any file passed to it via the paths argument 
    to the managed context.  Any Page managed objects are added to the
    Session object passed via the session argument. If the Session object
    is new a session window is created and displayed. */
- (void)addFiles:(NSArray *)paths toSession:(TSSTManagedSession *)session;

/*  These are the methods that actually parse the paths array passed
    to addFiles:toSession:. */
/*  Recurses through directories looking for archives, images and PDFs. */
//- (NSManagedObject *)groupForFile:(NSString *)filePath nested:(TSSTManagedGroup *)nested;

/*  Called when Simple Comic encounters a password protected
    archive.  Brings a password dialog forward. */
- (NSString*)passwordForArchiveWithPath:(NSString*)filename;

- (void)generateEncodingMenu;
/*  Generates a customized encoding menu for an archive.
    Removes all encodings that do not work with the the
    argument "string"  */
- (void)updateEncodingMenuTestedAgainst:(const char *)string;
/*  Modal that displays all available string encodings
    and allows the user to pick one. */
- (IBAction)testEncoding:(id)sender;
- (IBAction)testEncodingMenu:(id)sender;

/*  Launches the preferences window manager. */
- (IBAction)openPreferences:(id)sender;

//- (void)addBookmarkWithSession:(TSSTManagedSession *)session;
//- (void)addToHistoryWithGroup:(TSSTManagedGroup *)group;
//
//- (void)buildHistoryMenu;
//- (void)buildBookmarkMenu;
///* Recursive function for building the bookmark menu */
//- (void)buildSubMenu:(NSMenu *)menu withNode:(TSSTManagedBookmarkGroup *)node;
//
//- (IBAction)openBookmarkFromMenu:(id)sender;
/* Finds a givien BookmarkGroup object */
//- (TSSTManagedBookmarkGroup *)findBookmarkGroupWithIdentifier:(NSString *)identifier;

/*  Starts an NSOpenPanel with auxiliary view */
- (IBAction)addPages:(id)sender;
/*  These are called by modals that want to end */
- (IBAction)modalOK:(id)sender;
- (IBAction)modalCancel:(id)sender;

/* Takes user to the Simple Comic website. */
- (IBAction)donate:(id)sender;

- (IBAction)actionStub:(id)sender;


@end
