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
	SimpleComicAppDelegate.m
*/


#import "SimpleComicAppDelegate.h"
#import <Sparkle/Sparkle.h>
#import <XADMaster/XADArchive.h>
#import <Carbon/Carbon.h>
#import "TSSTSessionWindowController.h"
#import "TSSTSortDescriptor.h"
#import "TSSTPage.h"
#import "TSSTManagedGroup.h"
#import "TSSTManagedBookmarkGroup.h"
#import "TSSTManagedSession.h"
#import "SS_PrefsController.h"
#import "TSSTCustomValueTransformers.h"



NSString * TSSTPageOrder =         @"pageOrder";
NSString * TSSTPageZoomRate =      @"pageZoomRate";
NSString * TSSTFullscreen =        @"fullscreen";
NSString * TSSTSavedSelection =    @"savedSelection";
NSString * TSSTThumbnailSize =     @"thumbnailSize";
NSString * TSSTTwoPageSpread =     @"twoPageSpread";
NSString * TSSTPageScaleOptions =  @"scaleOptions";
NSString * TSSTIgnoreDonation =    @"ignoreDonation";
NSString * TSSTScrollPosition =    @"scrollPosition";
NSString * TSSTConstrainScale =    @"constrainScale";
NSString * TSSTZoomLevel =         @"zoomLevel";
NSString * TSSTViewRotation =      @"rotation";
NSString * TSSTBackgroundColor =   @"pageBackgroundColor";
NSString * TSSTSessionRestore =    @"sessionRestore";
NSString * TSSTScrollersVisible =  @"scrollersVisible";
NSString * TSSTAutoPageTurn =      @"autoPageTurn";
NSString * TSSTWindowAutoResize =  @"windowAutoResize";
NSString * TSSTLoupeDiameter =     @"loupeDiameter";
NSString * TSSTLoupePower =		   @"loupePower";
NSString * TSSTStatusbarVisible =  @"statusBarVisisble";
NSString * TSSTLonelyFirstPage =   @"lonelyFirstPage";
NSString * TSSTNestedArchives =	   @"nestedArchives";
NSString * TSSTUpdateSelection =   @"updateSelection";

NSString * TSSTSessionEndNotification = @"sessionEnd";


#pragma mark -
#pragma mark String Encoding Functions



static NSArray * allAvailableStringEncodings(void)
{
    NSStringEncoding encodings[] = {
        kCFStringEncodingMacRoman,
        kCFStringEncodingISOLatin1,
        kCFStringEncodingASCII,
        101,
        kCFStringEncodingWindowsLatin2,
        kCFStringEncodingMacCentralEurRoman,
        kCFStringEncodingDOSLatin2,
        101,
        kCFStringEncodingDOSJapanese,
        kCFStringEncodingMacJapanese,
        kCFStringEncodingShiftJIS_X0213_00,
        kCFStringEncodingISO_2022_JP,
        kCFStringEncodingEUC_JP,
        101,
        kCFStringEncodingGBK_95,
        kCFStringEncodingGB_18030_2000,
        101,
        kCFStringEncodingDOSChineseSimplif,
        kCFStringEncodingVISCII,
        kCFStringEncodingHZ_GB_2312,
        kCFStringEncodingEUC_CN,
        kCFStringEncodingGB_2312_80,
        101,
        kCFStringEncodingDOSChineseTrad,
        kCFStringEncodingBig5_HKSCS_1999,
        kCFStringEncodingBig5,
        101,
        kCFStringEncodingDOSKorean,
        kCFStringEncodingEUC_KR,
        kCFStringEncodingKSC_5601_87,
        kCFStringEncodingWindowsKoreanJohab,
        101,
        kCFStringEncodingWindowsCyrillic,
        kCFStringEncodingDOSCyrillic,
        kCFStringEncodingDOSRussian,
        kCFStringEncodingKOI8_R,
        kCFStringEncodingKOI8_U,
        101,
        kCFStringEncodingWindowsArabic,
        kCFStringEncodingISOLatinArabic,
        101,
        kCFStringEncodingISOLatinHebrew,
        kCFStringEncodingWindowsHebrew,
        101,
        kCFStringEncodingISOLatinGreek,
        kCFStringEncodingWindowsGreek,
        101,
        kCFStringEncodingISOLatin5,
        kCFStringEncodingWindowsLatin5,
        101,
        kCFStringEncodingISOLatinThai,
        kCFStringEncodingDOSThai,
        101,
        kCFStringEncodingWindowsVietnamese,
        kCFStringEncodingDOSPortuguese,
        kCFStringEncodingWindowsBalticRim,
        NSNotFound
    };
    
    NSMutableArray * codeNumbers = [NSMutableArray array];
    int counter = 0;
    NSStringEncoding encoding;
    while(encodings[counter] != NSNotFound)
    {
        if(encodings[counter] != 101)
        {
            encoding = CFStringConvertEncodingToNSStringEncoding(encodings[counter]);
        }
        else
        {
            encoding = 101;
        }
		
        [codeNumbers addObject: [NSNumber numberWithUnsignedInteger: encoding]];
        ++counter;
    }
    
    return [[codeNumbers retain] autorelease];
}



@implementation SimpleComicAppDelegate


@synthesize encodingSelection;


/*  Convenience method for adding metadata to the core data store.
    Used by Simple Comic to keep track of store versioning. */
+ (void)setMetadata:(NSString *)value forKey:(NSString *)key onStoreWithURL:(NSURL *)url managedBy:(NSPersistentStoreCoordinator *)coordinator
{
    NSPersistentStore * store = [coordinator persistentStoreForURL: url];
    NSMutableDictionary * metadata = [[coordinator metadataForPersistentStore: store] mutableCopy];
    [metadata setValue: value forKey: key];
    [coordinator setMetadata: metadata forPersistentStore: store];
    [metadata release];
}



/*  Sets up the user defaults and arrays of compatible file types. */
+ (void)initialize
{
    NSMutableDictionary* standardDefaults = [NSMutableDictionary dictionary];
	[standardDefaults setObject: [NSNumber numberWithBool: NO] forKey: TSSTPageOrder];
	[standardDefaults setObject: [NSNumber numberWithFloat: 0.1] forKey: TSSTPageZoomRate];
	[standardDefaults setObject: [NSNumber numberWithInt: 1] forKey: TSSTPageScaleOptions];
    [standardDefaults setObject: [NSNumber numberWithInt: 100] forKey: TSSTThumbnailSize];
    [standardDefaults setObject: [NSNumber numberWithBool: YES] forKey: TSSTTwoPageSpread];
    [standardDefaults setObject: [NSNumber numberWithBool: NO] forKey: TSSTIgnoreDonation];
    [standardDefaults setObject: [NSNumber numberWithBool: YES] forKey: TSSTConstrainScale];
    [standardDefaults setObject: [NSNumber numberWithBool: YES] forKey: TSSTScrollersVisible];
    [standardDefaults setObject: [NSNumber numberWithBool: YES] forKey: TSSTSessionRestore];
    [standardDefaults setObject: [NSNumber numberWithBool: YES] forKey: TSSTAutoPageTurn];
	[standardDefaults setObject: [NSArchiver archivedDataWithRootObject: [NSColor whiteColor]] forKey: TSSTBackgroundColor];
    [standardDefaults setObject: [NSNumber numberWithBool: YES] forKey: TSSTWindowAutoResize];
    [standardDefaults setObject: [NSNumber numberWithInt: 500] forKey: TSSTLoupeDiameter];
	[standardDefaults setObject: [NSNumber numberWithFloat: 2.0] forKey: TSSTLoupePower];
 	[standardDefaults setObject: [NSNumber numberWithBool: YES] forKey: TSSTStatusbarVisible];
    [standardDefaults setObject: [NSNumber numberWithBool: YES] forKey: TSSTLonelyFirstPage];
	[standardDefaults setObject: [NSNumber numberWithBool: YES] forKey: TSSTNestedArchives];
	[standardDefaults setObject: [NSNumber numberWithInt: 0] forKey: TSSTUpdateSelection];
	
	NSUserDefaultsController * sharedDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
	[sharedDefaultsController setInitialValues: standardDefaults];
	NSUserDefaults * defaults = [sharedDefaultsController defaults];
    [defaults registerDefaults: standardDefaults];
	
    id transformer = [[TSSTLastPathComponent new] autorelease];
	[NSValueTransformer setValueTransformer: transformer forName: @"TSSTLastPathComponent"];
}


- (void) dealloc
{
	[[NSUserDefaults standardUserDefaults] removeObserver: self forKeyPath: TSSTUpdateSelection];
	[[NSUserDefaults standardUserDefaults] removeObserver: self forKeyPath: TSSTSessionRestore];

    [sessions release];
    [preferences release];
    [super dealloc];
}


#pragma mark -
#pragma mark Application Delegate Methods


/*	Stores any files that were opened on launch till applicationDidFinishLaunching:
	is called. */
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	autoSave = nil;
	launchFiles = nil;
	launchInProgress = YES;
	preferences = nil;
	optionHeldAtlaunch = NO;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endSession:) name: TSSTSessionEndNotification object: nil];
	[[NSUserDefaults standardUserDefaults] addObserver: self forKeyPath: TSSTUpdateSelection options: 0 context: nil];
	[[NSUserDefaults standardUserDefaults] addObserver: self forKeyPath: TSSTSessionRestore options: 0 context: nil];
}



- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	[self generateEncodingMenu];
	/* Sets the Sparkle update feed to corespond to user prefs */
	NSURL * feedURL;
	if([[userDefaults valueForKey: TSSTUpdateSelection] intValue] == 0)
	{
		feedURL = [NSURL URLWithString:@"http://www.dancingtortoise.com/simplecomic/simplecomic.xml"];
	}
	else
	{
		feedURL = [NSURL URLWithString: @"http://www.dancingtortoise.com/simplecomic/simplecomic_beta.xml"];
	}
	[updater setFeedURL: feedURL];
	
	/* Starts the auto save timer */
	if([[userDefaults valueForKey: TSSTSessionRestore] boolValue])
	{
		autoSave = [NSTimer scheduledTimerWithTimeInterval: 30.0 target: self selector: @selector(saveContext) userInfo: nil repeats: YES];
	}
    sessions = [NSMutableArray new];
	[self sessionRelaunch];
	launchInProgress = NO;

	if(launchFiles)
	{
		TSSTManagedSession * session;
//		if (optionHeldAtlaunch)
//		{
//			NSMutableArray * looseImages = [NSMutableArray array];
//			for(NSString * path in launchFiles)
//			{
//				if([[TSSTManagedArchive archiveExtensions] containsObject: [[path pathExtension] lowercaseString]])
//				{
//					session = [self newSessionWithFiles: [NSArray arrayWithObject: path]];
//					[self windowForSession: session];
//				}
//				else {
//					[looseImages addObject: path];
//				}
//				
//				if ([looseImages count]> 0) {
//					session = [self newSessionWithFiles: looseImages];
//					[self windowForSession: session];
//				}
//				
//			}
//		}
//		else
//		{
			session = [self newSessionWithFiles: launchFiles];
			[self windowForSession: session];
//		}
		
		[launchFiles release];
		launchFiles = nil;
	}
}


- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{	
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	
	if(![[userDefaults valueForKey: TSSTSessionRestore] boolValue])
	{
		/* Goes through and deletes all active sessions if the user has auto save turned off */
		for(TSSTSessionWindowController * sessionWindow in sessions)
		{
			[[sessionWindow window] performClose: self];
		}
	}
	
    int reply = NSTerminateNow;
	/* TODO: some day I really need to add the fallback error handling */
    if(![self saveContext])
    {
        // Error handling wasn't implemented. Fall back to displaying a "quit anyway" panel.
        int alertReturn = NSRunAlertPanel(nil, @"Could not save changes while quitting. Quit anyway?" , @"Quit anyway", @"Cancel", nil);
        if (alertReturn == NSAlertAlternateReturn)
        {
            reply = NSTerminateCancel;	
        }
    }
    
    BOOL ignoreDonate = [[userDefaults valueForKey: TSSTIgnoreDonation] boolValue];
    if(reply != NSTerminateCancel && !ignoreDonate)
    {
        if([NSApp runModalForWindow: donationPanel] != NSCancelButton)
        {
            [self donate: self];
        }
        [donationPanel close];
    }
	
	return reply;
}


- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self managedObjectContext] undoManager];
}


/* Used to watch and react to pref changes */
- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object 
						change:(NSDictionary *)change 
					   context:(void *)context
{
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];

	if([keyPath isEqualToString: TSSTUpdateSelection])
	{
		NSURL * feedURL;
		if([[userDefaults valueForKey: TSSTUpdateSelection] intValue] == 0)
		{
			feedURL = [NSURL URLWithString:@"http://www.dancingtortoise.com/simplecomic/simplecomic.xml"];
		}
		else
		{
			feedURL = [NSURL URLWithString: @"http://www.dancingtortoise.com/simplecomic/simplecomic_beta.xml"];
		}
		[updater setFeedURL: feedURL];
	}
	else if([keyPath isEqualToString: TSSTSessionRestore])
	{
		[autoSave invalidate];
		autoSave = nil;
		if([[userDefaults valueForKey: TSSTSessionRestore] boolValue])
		{
			autoSave = [NSTimer scheduledTimerWithTimeInterval: 30.0 target: self selector: @selector(saveContext) userInfo: nil repeats: YES];
		}
	}
}



- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{	
	if(!launchInProgress)
	{
		TSSTManagedSession * session;
		session = [self newSessionWithFiles: filenames];
		[self windowForSession: session];
	}
	else
	{
		launchFiles = [filenames retain];
	}
}



//- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename;
//{	
//	if(!launchInProgress)
//	{
//		TSSTManagedSession * session;
//		session = [self newSessionWithFiles: [NSArray arrayWithObject: filename]];
//		[self windowForSession: session];
//		return YES;
//
//	}
//	
//	return NO;
//
////	else
////	{
////		launchFiles = [filenames retain];
////	}
//}


//- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
//{	
//	BOOL option = (GetCurrentKeyModifiers()&(optionKey) != 0);
//	if(!launchInProgress)
//	{
//		TSSTManagedSession * session;
//		if (option)
//		{
//			NSMutableArray * looseImages = [NSMutableArray array];
//			for(NSString * path in filenames)
//			{
//				if([[TSSTManagedArchive archiveExtensions] containsObject: [[path pathExtension] lowercaseString]])
//				{
//					session = [self newSessionWithFiles: [NSArray arrayWithObject: path]];
//					[self windowForSession: session];
//				}
//				else
//				{
//					[looseImages addObject: path];
//				}
//				
//				if ([looseImages count]> 0) {
//					session = [self newSessionWithFiles: looseImages];
//					[self windowForSession: session];
//				}
//				
//			}
//		}
//		else
//		{
//			session = [self newSessionWithFiles: filenames];
//			[self windowForSession: session];
//		}
//	}
//	else
//	{
//		launchFiles = [filenames retain];
//		optionHeldAtlaunch = option;
//	}
//}



#pragma mark -
#pragma mark Core Data



- (NSManagedObjectModel *)managedObjectModel
{
    if (managedObjectModel != nil)
	{
        return managedObjectModel;
    }
	
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles: nil] retain];    
    return managedObjectModel;
}


/*	Returns the persistent store coordinator for the application.  This 
	implementation will create and return a coordinator, having added the 
	store for the application to it.  (The folder for the store is created, 
	if necessary.) */
- (NSPersistentStoreCoordinator *) persistentStoreCoordinator
{	
    if (persistentStoreCoordinator != nil)
	{
        return persistentStoreCoordinator;
    }
	
    NSURL * url;
    NSError * error = nil;
    
	NSFileManager * fileManager = [NSFileManager defaultManager];
    NSString * applicationSupportFolder = [self applicationSupportFolder];
    if (![fileManager fileExistsAtPath: applicationSupportFolder isDirectory: NULL] )
	{
		if(![fileManager createDirectoryAtPath: applicationSupportFolder withIntermediateDirectories: YES attributes: nil error: &error])
		{
			NSLog(@"%@",[error localizedDescription]);
		}
    }
	
	NSDictionary * storeOptions = [NSDictionary dictionaryWithObject: [NSNumber numberWithBool: YES] 
															  forKey: NSMigratePersistentStoresAutomaticallyOption];
    url = [NSURL fileURLWithPath: [applicationSupportFolder stringByAppendingPathComponent: @"SimpleComic.sql"]];
	
	error = nil;
	NSDictionary * storeInfo = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType: NSSQLiteStoreType URL: url error: &error];
	if(error)
	{
		NSLog(@"%@",[error localizedDescription]);
	}    

	if(![[storeInfo valueForKey: @"viewVersion"] isEqualToString: @"Version 1706"])
	{
		if(![fileManager removeItemAtPath: [url path] error: &error])
		{
			NSLog(@"%@",[error localizedDescription]);
		}
	}
	
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
	
    if (![persistentStoreCoordinator addPersistentStoreWithType: NSSQLiteStoreType configuration: nil URL: url options: storeOptions error: &error])
	{
        [[NSApplication sharedApplication] presentError: error];
    }    
	
	[SimpleComicAppDelegate setMetadata: @"Version 1706" forKey: @"viewVersion" onStoreWithURL: url managedBy: persistentStoreCoordinator];

    return persistentStoreCoordinator;
}


- (NSManagedObjectContext *) managedObjectContext
{
    if (managedObjectContext != nil)
	{
        return managedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
	{
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    
    return managedObjectContext;
} 



/*  Method creates an application support directory for Simpl Comic if one
    is does not already exist.
    @return The absolute path to Simple Comic's application support directory 
	as a string.  */
- (NSString *)applicationSupportFolder
{
	
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString * basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent: @"Simple Comic"];
}



- (BOOL)saveContext
{
    TSSTSessionWindowController * controller;
    for (controller in sessions)
    {
        [controller updateSessionObject];
    }
    
    NSError * error;
    NSManagedObjectContext * context = [self managedObjectContext];
	[context retain];
	[context lock];
    BOOL saved = NO;
    if (context != nil)
	{
        if ([context commitEditing])
		{
            if (![context save: &error])
			{
				// This default error handling implementation should be changed to make sure the error presented includes application specific error recovery. 
				// For now, simply display 2 panels.
				[[NSApplication sharedApplication] presentError: error];
            }
            else 
            {
                saved = YES;
            }
        }
    }
	
	[context unlock];
	[context release];
    return saved;
}



#pragma mark -
#pragma mark Session Managment



- (void)windowForSession:(TSSTManagedSession *)settings
{
	NSArray * existingSessions = [sessions valueForKey: @"session"];
    if([[settings valueForKey: @"images"] count] > 0 && ![existingSessions containsObject: settings])
    {
        TSSTSessionWindowController * comicWindow = [[TSSTSessionWindowController alloc] initWithSession: settings];
        [sessions addObject: comicWindow];
        [comicWindow release];
        [comicWindow showWindow: self];
    }
}



- (void)endSession:(NSNotification *)notification
{
	TSSTSessionWindowController * controller = [notification object];
	TSSTManagedSession * sessionToRemove = [[controller session] retain];
	[sessions removeObject: controller];
	[[self managedObjectContext] deleteObject: sessionToRemove];
	[sessionToRemove release];
}



- (void)sessionRelaunch
{
    TSSTManagedSession * session;
	NSFetchRequest * sessionRequest = [NSFetchRequest new];
	[sessionRequest setEntity: [NSEntityDescription entityForName: @"Session" inManagedObjectContext: [self managedObjectContext]]];
	NSError * fetchError;
	NSArray * managedSessions = [[self managedObjectContext] executeFetchRequest: sessionRequest error: &fetchError];
	[sessionRequest release];
	for(session in managedSessions)
	{
		if([[session valueForKey: @"groups"] count] <= 0)
		{
			[[self managedObjectContext] deleteObject: session];
		}
		else
		{
			
			[self windowForSession: session];
		}
	}
}


- (TSSTManagedSession *)newSessionWithFiles:(NSArray *)files
{
    TSSTManagedSession * sessionDescription = [NSEntityDescription insertNewObjectForEntityForName: @"Session" inManagedObjectContext: [self managedObjectContext]];
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    
    [sessionDescription setValue: [defaults valueForKey: TSSTPageScaleOptions] forKey: TSSTPageScaleOptions];
    [sessionDescription setValue: [defaults valueForKey: TSSTPageOrder] forKey: TSSTPageOrder];
    [sessionDescription setValue: [defaults valueForKey: TSSTTwoPageSpread] forKey: TSSTTwoPageSpread];
	
    [self addFiles: files toSession: sessionDescription];

	return sessionDescription;
}



- (void)addFiles:(NSArray *)paths toSession:(TSSTManagedSession *)session
{	
//	[[self managedObjectContext] retain];
//	[[self managedObjectContext] lock];
	NSFileManager * fileManager = [NSFileManager defaultManager];
	NSString * path, * fileExtension;
	BOOL isDirectory, exists;
    NSManagedObject * fileDescription;
	NSMutableSet * pageSet = [[NSMutableSet alloc] initWithSet: [session valueForKey: @"images"]];
	for (path in paths)
	{
		fileDescription = nil;
		fileExtension = [[path pathExtension] lowercaseString];
		exists = [fileManager fileExistsAtPath: path isDirectory: &isDirectory];
		if(exists && ![[[path lastPathComponent] substringToIndex: 1] isEqualToString: @"."])
		{
			if(isDirectory)
			{
				fileDescription = [NSEntityDescription insertNewObjectForEntityForName: @"ImageGroup" inManagedObjectContext: [self managedObjectContext]];
				[fileDescription setValue: path forKey: @"path"];
				[fileDescription setValue: [path lastPathComponent] forKey: @"name"];
				[(TSSTManagedGroup *)fileDescription nestedFolderContents];
			}
			else if([[TSSTManagedArchive archiveExtensions] containsObject: fileExtension])
			{
				fileDescription = [NSEntityDescription insertNewObjectForEntityForName: @"Archive" inManagedObjectContext: [self managedObjectContext]];
				[fileDescription setValue: path forKey: @"path"];
				[fileDescription setValue: [path lastPathComponent] forKey: @"name"];
				[(TSSTManagedArchive *)fileDescription nestedArchiveContents];
			}
			else if([fileExtension isEqualToString: @"pdf"])
			{
				fileDescription = [NSEntityDescription insertNewObjectForEntityForName: @"PDF" inManagedObjectContext: [self managedObjectContext]];
				[fileDescription setValue: path forKey: @"path"];
				[fileDescription setValue: [path lastPathComponent] forKey: @"name"];
				[(TSSTManagedPDF *)fileDescription pdfContents];
			}
			else if([[TSSTPage imageExtensions] containsObject: fileExtension] || [[TSSTPage textExtensions] containsObject: fileExtension])
			{
				fileDescription = [NSEntityDescription insertNewObjectForEntityForName: @"Image" inManagedObjectContext: [self managedObjectContext]];
				[fileDescription setValue: path forKey: @"imagePath"];
			}
			
			if([fileDescription class] == [TSSTManagedGroup class] || [fileDescription superclass] == [TSSTManagedGroup class])
			{
				[pageSet unionSet: [(TSSTManagedGroup *)fileDescription nestedImages]];
				[fileDescription setValue: session forKey: @"session"];
			}
			else if ([fileDescription class] == [TSSTPage class])
			{
				[pageSet addObject: fileDescription];
			}
			
			if(fileDescription)
			{
				[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL: [NSURL fileURLWithPath: path]];
			}
		}
	}
	
	[session setValue: pageSet forKey: @"images"];
	[pageSet release];
//	[[self managedObjectContext] unlock];
//	[[self managedObjectContext] release];
}


#pragma mark -
#pragma mark Actions


// Launches open modal.
- (IBAction)addPages:(id)sender
{
	// Creates a new modal.
	NSOpenPanel * addPagesModal = [NSOpenPanel openPanel];
	[addPagesModal setAllowsMultipleSelection: YES];
    [addPagesModal setCanChooseDirectories: YES];
	
	NSMutableArray * allAllowedFilesExtensions = [NSMutableArray arrayWithArray: [TSSTManagedArchive archiveExtensions]];
	[allAllowedFilesExtensions addObjectsFromArray: [TSSTPage imageExtensions]];
    
	if([addPagesModal runModalForTypes: allAllowedFilesExtensions] !=  NSCancelButton)
	{
		TSSTManagedSession * session = [self newSessionWithFiles: [addPagesModal filenames]];
		[self windowForSession: session];
	}
}



/*  Kills the password and encoding modals if the OK button was  clicked. */
- (IBAction)modalOK:(id)sender
{
    [NSApp stopModalWithCode: NSOKButton]; 
}



/*  Kills the password and encoding modals if the Cancel button was clicked. */
- (IBAction)modalCancel:(id)sender
{
    [NSApp stopModalWithCode: NSCancelButton]; 
}



- (IBAction)openPreferences:(id)sender
{
    if(!preferences)
    {
        preferences = [[SS_PrefsController alloc] initWithPanesSearchPath: nil];
        
        // Set which panes are included, and their order.
        [preferences setPanesOrder: [NSArray arrayWithObjects: @"Advanced", nil]];
    }
    [preferences showPreferencesWindow];
}



- (IBAction)donate:(id)sender
{
    NSURL * donationPage = [NSURL URLWithString: @"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=arauchfuss@gmail.com&item_name=Simple+Comic&item_number=Donation&currency_code=USD"];
    [[NSWorkspace sharedWorkspace] openURL: donationPage];
}



#pragma mark -
#pragma mark Archive Encoding Handling



- (IBAction)testEncodingMenu:(id)sender
{
	[NSApp runModalForWindow: encodingPanel];
}



- (void)generateEncodingMenu
{
	NSMenu * encodingMenu = [encodingPopup menu];
	NSMenuItem * encodingMenuItem;
    NSArray * allEncodings = allAvailableStringEncodings();
    NSNumber * encodingIdent;
    NSStringEncoding stringEncoding;
    NSString * encodingName;
	self.encodingSelection = 0;
	[encodingMenu setAutoenablesItems: NO];
	for(encodingMenuItem in [encodingMenu itemArray])
	{
		[encodingMenu removeItem: encodingMenuItem];
	}
	
    for(encodingIdent in allEncodings)
    {
		stringEncoding = [encodingIdent unsignedIntegerValue];
        encodingName = [NSString localizedNameOfStringEncoding: stringEncoding];
        if(stringEncoding == 101)
        {
            encodingMenuItem = [NSMenuItem separatorItem];
            [encodingMenu addItem: encodingMenuItem];
        }
        else if(encodingName && ![encodingName isEqualToString: @""])
        {
            encodingMenuItem = [[NSMenuItem alloc] initWithTitle: encodingName action: nil keyEquivalent: @""];
            [encodingMenuItem setRepresentedObject: encodingIdent];
            [encodingMenu addItem: encodingMenuItem];
            [encodingMenuItem release];
        }
    }
    [encodingPopup bind: @"selectedIndex" toObject: self withKeyPath: @"encodingSelection" options: nil];
}



- (void)updateEncodingMenuTestedAgainst:(NSData *)data
{
    
    NSStringEncoding stringEncoding;
    NSMenuItem * encodingMenuItem;
    NSString * testText;
    
    for(encodingMenuItem in [[encodingPopup menu] itemArray])
    {
        stringEncoding = [[encodingMenuItem representedObject] unsignedIntegerValue];
        [encodingMenuItem setEnabled: NO];
        if(![encodingMenuItem isSeparatorItem])
        {
			testText = [[NSString alloc] initWithData: data encoding: stringEncoding];

			[encodingMenuItem setEnabled: testText ? YES : NO];
			[testText release];
        }
    }
}


/*  Called when Simple Comic encounters a password protected
    archive.  Brings a password dialog forward. */
- (NSString*)passwordForArchiveWithPath:(NSString*)filename
{
    NSString* password = nil;
	[passwordField setStringValue: @""];
    if([NSApp runModalForWindow: passwordPanel] != NSCancelButton)
    {
        password = [passwordField stringValue];
    }
	
    [passwordPanel close];
    return password;
}



-(NSStringEncoding)archive:(XADArchive *)archive 
		   encodingForData:(NSData *)data 
					 guess:(NSStringEncoding)guess 
				confidence:(float)confidence
{
    NSString * testText = [[NSString alloc] initWithData: data encoding: guess];
    if(confidence < 0.8 || !testText)
    {
		NSMenu * encodingMenu = [encodingPopup menu];
        [self updateEncodingMenuTestedAgainst: data];
        NSArray * encodingIdentifiers = [[encodingMenu itemArray] valueForKey: @"representedObject"];
		
		NSUInteger index = [encodingIdentifiers indexOfObject: [NSNumber numberWithUnsignedInteger: guess]];
		NSUInteger counter = 0;
//		NSStringEncoding encoding;
		NSNumber * encoding;
		while(!testText)
		{
			[testText release];
			encoding = [encodingIdentifiers objectAtIndex: counter];
			if ([encoding class] != [NSNull class]) {
				testText = [[NSString alloc] initWithData: data encoding: [encoding unsignedIntegerValue]];
			}
			index = counter++;
		}

        if(index != NSNotFound)
        {
            self.encodingSelection = index;
        }
        
        encodingTestData = data;
		
        [self testEncoding: self];
		guess = NSNotFound;
        if([NSApp runModalForWindow: encodingPanel] != NSCancelButton)
        {
            guess = [[[encodingMenu itemAtIndex: encodingSelection] representedObject] unsignedIntegerValue];
        }
        [encodingPanel close];
        [archive setNameEncoding: guess];
    }
    
	[testText release];
    return guess;
}



- (IBAction)testEncoding:(id)sender
{
    NSMenuItem * encodingMenuItem = [[encodingPopup menu] itemAtIndex: encodingSelection];
	NSString * testText = [[NSString alloc] initWithData: encodingTestData encoding: [[encodingMenuItem representedObject] unsignedIntegerValue]];
    
    if(!testText)
    {
        testText = @"invalid Selection";
    }
    
    [encodingTestField setStringValue: testText];
	[testText release];
}



- (IBAction)actionStub:(id)sender
{
    
}


- (IBAction)endLaunchPanel:(id)sender
{
	[launchPanel close];
}


@end


