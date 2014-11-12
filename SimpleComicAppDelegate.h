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
	SimpleComicAppDelegate.h
*/


#import <Cocoa/Cocoa.h>


@class SS_PrefsController;
@class TSSTSessionWindowController;
@class TSSTManagedArchive;
@class TSSTManagedGroup;
@class TSSTManagedPDF;
@class TSSTManagedSession;
@class DTPreferencesController;

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
extern NSString * TSSTSessionEndNotification;


/*!
    This class is the application delegate.
    It handles the following:
 
    The Core Data store
    File loading
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
    NSData					   * encodingTestData;
    NSInteger					 encodingSelection;
    IBOutlet NSPopUpButton     * encodingPopup;

    IBOutlet NSPanel * donationPanel;
	
	IBOutlet NSPanel * launchPanel;
	
/*  Core Data stuff. */
    NSManagedObjectModel		 * managedObjectModel;
    NSManagedObjectContext		 * managedObjectContext;
	NSPersistentStoreCoordinator * persistentStoreCoordinator;
	
/* Auto-save timer */
	NSTimer * autoSave;

/*  Window controller for preferences. */
    DTPreferencesController      * preferences;
    
/*  This is the array that maintains all of the session window managers. */
    NSMutableArray * sessions;
    
/*	Vars to delay the loading of files from an app launch until the core data store
	has finished initializing */
    BOOL      launchInProgress;
	BOOL	  optionHeldAtlaunch;
	NSArray	* launchFiles;
	
}


/* Bound to the encoding list drop down. */
@property (assign) NSInteger encodingSelection;

/*  Convenience method for adding metadata to the core data store.
    Used by Simple Comic to keep track of store versioning. */
+ (void)setMetadata:(NSString *)value forKey:(NSString *)key onStoreWithURL:(NSURL *)url managedBy:(NSPersistentStoreCoordinator *)coordinator;

/*  Core Data methods, slightly altered boilerplate. */
@property (readonly, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, copy) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong) NSManagedObjectContext *managedObjectContext;
@property (readonly, copy) NSString *applicationSupportFolder;
@property (readonly) BOOL saveContext;


/*  Creates a new Session object based on user prefs and then 
    passes the files array to addFiles:toSesion: */
- (TSSTManagedSession *)newSessionWithFiles:(NSArray *)files NS_RETURNS_NOT_RETAINED;

/*  This method is called every time an existing session needs
    to be made visible to a user. */
- (void)windowForSession:(TSSTManagedSession *)session;

/*  When an end session notification is received this method
	is called. */
- (void)endSession:(NSNotification *)notification;

/*  This method is called at launch, it iterates through all of the saved
    sessions calling windowForSession: for each in turn. */
- (void)sessionRelaunch;
    
/*  This method adds any file passed to it to a session.  This includes recursive
	parsing of archives and folders. */
- (void)addFiles:(NSArray *)paths toSession:(TSSTManagedSession *)session;

/*  Called when Simple Comic encounters a password protected
    archive.  Brings a password dialog forward. */
- (NSString*)passwordForArchiveWithPath:(NSString*)filename;


- (void)generateEncodingMenu;
/*  Updates the encoding menu for an archive.
    Grays out all encodings that do not work with the
    argument string  */
- (void)updateEncodingMenuTestedAgainst:(NSData *)data;
/*  Modal that displays all available string encodings
    and allows the user to pick one. */
- (IBAction)testEncoding:(id)sender;
- (IBAction)testEncodingMenu:(id)sender;

/*  Launches the preferences window manager. */
- (IBAction)openPreferences:(id)sender;

/*  Starts an NSOpenPanel with auxiliary view */
- (IBAction)addPages:(id)sender;
/*  These are called by modals that want to end */
- (IBAction)modalOK:(id)sender;
- (IBAction)modalCancel:(id)sender;

/* Takes user to the Simple Comic paypal page. */
- (IBAction)endLaunchPanel:(id)sender;
- (IBAction)actionStub:(id)sender;

@end
