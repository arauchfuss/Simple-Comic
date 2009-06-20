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
	SimpleComicAppDelegate.m
*/


#import "SimpleComicAppDelegate.h"
#import <Sparkle/Sparkle.h>
#import <XADMaster/XADArchive.h>
#import "TSSTSessionWindowController.h"
#import "TSSTSortDescriptor.h"
//#import "TSSTShortcutController.h"
#import "TSSTPage.h"
#import "TSSTManagedGroup.h"
#import "TSSTManagedBookmarkGroup.h"
//#import "TSSTManagedBookmark.h"
#import "TSSTManagedSession.h"
#import "SS_PrefsController.h"
#import "TSSTCustomValueTransformers.h"
//#import "TSSTBookmarkWindowController.h"


@class TSSTHumanReadableIndex;


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


#pragma mark -
#pragma mark String Encoding Functions



static NSArray * allAvailableStringEncodings(void)
{
    unsigned long encodings[] = {
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
    unsigned long encoding;
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
		
        [codeNumbers addObject: [NSNumber numberWithUnsignedLong: encoding]];
        ++counter;
    }
    
    return codeNumbers;
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

    transformer = [[TSSTHumanReadableIndex new] autorelease];
	[NSValueTransformer setValueTransformer: transformer forName: @"TSSTHumanReadableIndex"];
}


- (void) dealloc
{
	[[NSUserDefaults standardUserDefaults] removeObserver: self forKeyPath: TSSTUpdateSelection];

    [sessions release];
    [preferences release];
    [super dealloc];
}


#pragma mark -
#pragma mark Application Delegate Methods


- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	launchFiles = nil;
	launchInProgress = YES;
	preferences = nil;
	[[NSUserDefaults standardUserDefaults] addObserver: self forKeyPath: TSSTUpdateSelection options: 0 context: nil];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSURL * feedURL;
	if([[[NSUserDefaults standardUserDefaults] valueForKey: TSSTUpdateSelection] intValue] == 0)
	{
		feedURL = [NSURL URLWithString:@"http://www.dancingtortoise.com/simplecomic/simplecomic.xml"];
	}
	else
	{
		feedURL = [NSURL URLWithString: @"http://www.dancingtortoise.com/simplecomic/simplecomic_beta.xml"];
	}
	[updater setFeedURL: feedURL];
	
    [NSTimer scheduledTimerWithTimeInterval: 30.0 target: self selector: @selector(saveContext) userInfo: nil repeats: YES];
    sessions = [NSMutableArray new];
	[self sessionRelaunch];
//	[self buildBookmarkMenu];
	launchInProgress = NO;
//	[bookmarkMenu setDelegate: self];

	if(launchFiles)
	{
		TSSTManagedSession * session = [self newSessionWithFiles: launchFiles];
		[self windowForSession: session];
		[launchFiles release];
		launchFiles = nil;
	}
}


- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{	
//	TSSTManagedSession * sessionToRemove;
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	BOOL saveSessions = [[userDefaults valueForKey: TSSTSessionRestore] boolValue];
	
	if(!saveSessions)
	{
		/* Goes through and deletes all active sessions if the user has auto save turned off */
		for(TSSTSessionWindowController * sessionWindow in sessions)
		{
			[sessionWindow close];
			[sessionWindow prepareToEnd];
			[[self managedObjectContext] deleteObject: [sessionWindow session]];
		}
	}
	
    int reply = NSTerminateNow;
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


- (void)applicationWillBecomeActive:(NSNotification *)aNotification
{
//	[sessions setValue: [[NSUserDefaults standardUserDefaults] valueForKey: TSSTFullscreen] forKeyPath: @"session.fullscreen"];
}


- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object 
						change:(NSDictionary *)change 
					   context:(void *)context
{
	if([keyPath isEqualToString: TSSTUpdateSelection])
	{
		NSURL * feedURL;
		if([[[NSUserDefaults standardUserDefaults] valueForKey: TSSTUpdateSelection] intValue] == 0)
		{
			feedURL = [NSURL URLWithString:@"http://www.dancingtortoise.com/simplecomic/simplecomic.xml"];
		}
		else
		{
			feedURL = [NSURL URLWithString: @"http://www.dancingtortoise.com/simplecomic/simplecomic_beta.xml"];
		}
		[updater setFeedURL: feedURL];
	}
}



- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
	if(!launchInProgress)
	{
		TSSTManagedSession * session = [self newSessionWithFiles: filenames];
		[self windowForSession: session];
	}
	else
	{
		launchFiles = [filenames retain];
	}
}


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


/**
 Returns the persistent store coordinator for the application.  This 
 implementation will create and return a coordinator, having added the 
 store for the application to it.  (The folder for the store is created, 
 if necessary.)
 */
- (NSPersistentStoreCoordinator *) persistentStoreCoordinator
{	
    if (persistentStoreCoordinator != nil)
	{
        return persistentStoreCoordinator;
    }
	
    NSURL * url;
    NSError * error;
    
	NSFileManager * fileManager = [NSFileManager defaultManager];
    NSString * applicationSupportFolder = [self applicationSupportFolder];
    if (![fileManager fileExistsAtPath: applicationSupportFolder isDirectory: NULL] )
	{
        [fileManager createDirectoryAtPath: applicationSupportFolder attributes: nil];
    }
	
	NSDictionary * storeOptions = [NSDictionary dictionaryWithObject: [NSNumber numberWithBool: YES] 
															  forKey: NSMigratePersistentStoresAutomaticallyOption];
    url = [NSURL fileURLWithPath: [applicationSupportFolder stringByAppendingPathComponent: @"SimpleComic.sql"]];
	
	NSDictionary * storeInfo = [NSPersistentStoreCoordinator metadataForPersistentStoreWithURL: url error: &error];
    
	if(![[storeInfo valueForKey: @"viewVersion"] isEqualToString: @"Version 1704"])
	{
		[fileManager removeFileAtPath: [url path] handler: nil];
	}
	
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
	
    if (![persistentStoreCoordinator addPersistentStoreWithType: NSSQLiteStoreType configuration: nil URL: url options: storeOptions error: &error])
	{
        [[NSApplication sharedApplication] presentError: error];
    }    
	
	[SimpleComicAppDelegate setMetadata: @"Version 1704" forKey: @"viewVersion" onStoreWithURL: url managedBy: persistentStoreCoordinator];

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
//		[settings setValue: [[NSUserDefaults standardUserDefaults] valueForKey: TSSTFullscreen] forKeyPath: TSSTFullscreen];
    }
}



- (void)endSession:(TSSTSessionWindowController *)manager
{
	TSSTManagedSession * sessionToRemove = [[manager session] retain];
	[sessions removeObject: manager];
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
	[[self managedObjectContext] retain];
	[[self managedObjectContext] lock];
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
	[[self managedObjectContext] unlock];
	[[self managedObjectContext] release];
}



#pragma mark -
#pragma mark Process Files



/*	This is the method that does the initial recursion though all directories that are passed
	when a new file is opened.
*/
//- (NSManagedObject *)groupForFile:(NSString *)filePath nested:(TSSTManagedGroup *)nested
//{
//	NSArray * nestedFiles;
//    NSManagedObject * fileDescription = nil;
//	NSManagedObject * nestedDescription;
//
//
//	if(exists)
//	{
//		if(isDirectory)
//		{
//			nestedFiles = [fileManager directoryContentsAtPath: filePath];
//			fileDescription = [NSEntityDescription insertNewObjectForEntityForName: @"ImageGroup" inManagedObjectContext: [self managedObjectContext]];
//			[fileDescription setValue: filePath forKey: @"path"];
//			[fileDescription setValue: [filePath lastPathComponent] forKey: @"name"];
//			
//			for (path in nestedFiles)
//			{
//				nestedDescription = nil;
//				path = [filePath stringByAppendingPathComponent: path];
//				nestedDescription = [self groupForFile: path nested: (TSSTManagedGroup *)fileDescription];
//				[nestedDescription setValue: fileDescription forKey: @"group"];
//			}
//		}
//		else if([[TSSTPage imageExtensions] containsObject: fileExtension] && nested && ![[[filePath lastPathComponent] substringToIndex: 1] isEqualToString: @"."])
//		{
//			TSSTPage * imageDescription = [NSEntityDescription insertNewObjectForEntityForName: @"Image" inManagedObjectContext: [self managedObjectContext]];
//			[imageDescription setValue: filePath forKey: @"imagePath"];
//			[imageDescription setValue: nested forKey: @"group"];
//		}
//		else if([[TSSTPage imageExtensions] containsObject: fileExtension] && ![[[filePath lastPathComponent] substringToIndex: 1] isEqualToString: @"."])
//		{
//			fileDescription = [NSEntityDescription insertNewObjectForEntityForName: @"Image" inManagedObjectContext: [self managedObjectContext]];
//			[fileDescription setValue: filePath forKey: @"imagePath"];
//		}
//		else if([[TSSTManagedArchive archiveExtensions] containsObject: fileExtension] && ![[[filePath lastPathComponent] substringToIndex: 1] isEqualToString: @"."])
//		{
//			fileDescription = [NSEntityDescription insertNewObjectForEntityForName: @"Archive" inManagedObjectContext: [self managedObjectContext]];
//			[fileDescription setValue: filePath forKey: @"path"];
//			[fileDescription setValue: [filePath lastPathComponent] forKey: @"name"];
//			[(TSSTManagedArchive *)fileDescription nestedArchiveContents];
//		}
//		else if([fileExtension isEqualToString: @"pdf"])
//		{
//			fileDescription = [NSEntityDescription insertNewObjectForEntityForName: @"PDF" inManagedObjectContext: [self managedObjectContext]];
//			[fileDescription setValue: filePath forKey: @"path"];
//			[fileDescription setValue: [filePath lastPathComponent] forKey: @"name"];
//			[(TSSTManagedPDF *)fileDescription pdfContents];
//		}
//	}
//	
//	if(fileDescription)
//	{
//		[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL: [NSURL fileURLWithPath: filePath]];
//	}
//
//    return fileDescription;
//}


//- (TSSTManagedBookmarkGroup *)findBookmarkGroupWithIdentifier:(NSString *)identifier
//{
//	NSFetchRequest * groupRequest = [NSFetchRequest new];
//	[groupRequest setEntity: [NSEntityDescription entityForName: @"BookmarkGroup" inManagedObjectContext: [self managedObjectContext]]];
//	NSError * fetchError;
//	NSArray * bookmarkNodes = [[self managedObjectContext] executeFetchRequest: groupRequest error: &fetchError];
//	[groupRequest release];
//	
//	TSSTManagedBookmarkGroup * bookmarkGroup;
//	if([bookmarkNodes count] <= 0)
//	{
//		bookmarkGroup = [NSEntityDescription insertNewObjectForEntityForName: @"BookmarkGroup" inManagedObjectContext: [self managedObjectContext]];
//		[bookmarkGroup setValue: [identifier capitalizedString] forKey: @"name"];
//		[bookmarkGroup setValue: identifier forKey: @"identifier"];
//	}
//	else
//	{
//		bookmarkGroup = [bookmarkNodes objectAtIndex: 0];
//	}
//	
//	return bookmarkGroup;
//}


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
        [preferences setPanesOrder: [NSArray arrayWithObjects:@"General", @"Advanced", nil]];
    }
    [preferences showPreferencesWindow];
}



//- (void)addToHistoryWithGroup:(TSSTManagedGroup *)group
//{
//	if([group class] == [TSSTManagedArchive class])
//	{
//		TSSTManagedBookmarkGroup * historyGroup = [self findBookmarkGroupWithIdentifier: @"history"];
//		NSArray * historyItems = [[historyGroup valueForKey: @"bookmarks"] allObjects];
//		NSArray * aliases = [historyItems valueForKey: @"alias"];
//		NSInteger index = [aliases indexOfObject: group.alias];
//		
//		if(index == NSNotFound)
//		{
//			TSSTManagedArchive * parentArchive = [group valueForKey: @"topLevelGroup"];
//			NSString * name = [[parentArchive valueForKey: @"path"] lastPathComponent];
//			
//			NSEntityDescription * historyItem = [NSEntityDescription insertNewObjectForEntityForName: @"Bookmark" inManagedObjectContext: [self managedObjectContext]];
//			[historyItem setValue: name  forKey: @"name"];
//			[historyItem setValue: [parentArchive valueForKey: @"path"] forKey: @"filePath"];
//			[historyItem setValue: historyGroup forKey: @"group"];	
//		}
//	}
//}
//
//
//
//- (void)addBookmarkWithSession:(TSSTManagedSession *)session
//{
//	NSArray * images = [[session valueForKey: @"images"] allObjects];
//	
//	TSSTSortDescriptor * fileNameSort = [[TSSTSortDescriptor alloc] initWithKey: @"imagePath" ascending: YES];
//	TSSTSortDescriptor * archivePathSort = [[TSSTSortDescriptor alloc] initWithKey: @"group.name" ascending: YES];
//	NSArray * imageSort = [NSArray arrayWithObjects: archivePathSort, fileNameSort, nil];
//	[fileNameSort release];
//	[archivePathSort release];
//	images = [images sortedArrayUsingDescriptors: imageSort];
//	
//	TSSTPage * selectedPage = [images objectAtIndex: [[session valueForKey: @"selection"] intValue]];
//	TSSTManagedGroup * group = [selectedPage valueForKeyPath: @"group"];
//	if([group class] == [TSSTManagedArchive class])
//	{
//		TSSTManagedArchive * parentArchive = [group valueForKey: @"topLevelGroup"];
//		NSString * topPath = [[parentArchive valueForKey: @"path"] lastPathComponent];
//		NSString * bookmarkName = [NSString stringWithFormat: @"%@ %@", topPath, [[selectedPage valueForKeyPath: @"imagePath"] lastPathComponent]];
//		[bookmarkNameField setStringValue: bookmarkName];
//		
//		if([NSApp runModalForWindow: bookmarkAddPanel] != NSCancelButton)
//		{
//			NSEntityDescription * bookmark = [NSEntityDescription insertNewObjectForEntityForName: @"Bookmark" inManagedObjectContext: [self managedObjectContext]];
//			[bookmark setValue: [bookmarkNameField stringValue]  forKey: @"name"];
//			[bookmark setValue: [parentArchive valueForKey: @"path"] forKey: @"filePath"];
//			[bookmark setValue: [selectedPage valueForKey: @"deconflictionName"] forKey: @"pageName"];
//			[bookmark setValue: [[bookmarkGroupAddController selectedObjects] objectAtIndex: 0] forKey: @"group"];
//		}
//		
//		[bookmarkAddPanel close];
//	}
//}


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
	NSMenuItem * encodingMenuItem;
    NSArray * allEncodings = allAvailableStringEncodings();
    NSNumber * encodingIdent;
    NSStringEncoding stringEncoding;
    NSString * encodingName;
	
	[encodingMenu setAutoenablesItems: NO];
	for(encodingMenuItem in [encodingMenu itemArray])
	{
		[encodingMenu removeItem: encodingMenuItem];
	}
	
    for(encodingIdent in allEncodings)
    {
        stringEncoding = [encodingIdent unsignedLongValue];
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
            [encodingMenuItem setTag: stringEncoding];
            [encodingMenu addItem: encodingMenuItem];
            [encodingMenuItem release];
        }
    }
    
}


- (void)updateEncodingMenuTestedAgainst:(const char *)string
{
    
    NSStringEncoding stringEncoding;
    NSMenuItem * encodingMenuItem;
    NSString * testText;
    
    for(encodingMenuItem in [encodingMenu itemArray])
    {
        stringEncoding = [[encodingMenuItem representedObject] unsignedLongValue];
        [encodingMenuItem setEnabled: NO];
        if(stringEncoding != 101)
        {
            testText = [[NSString alloc] initWithCString: string encoding: stringEncoding];
            if(testText)
            {
                [encodingMenuItem setEnabled: YES];
            }
            
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


-(NSStringEncoding)archive: (XADArchive *)archive
           encodingForName: (const char *)bytes
                     guess: (NSStringEncoding)guess
                confidence: (float)confidence
{
    NSString * testText = [NSString stringWithCString: bytes encoding: guess];
    if(confidence < 0.8 || !testText)
    {
		[self generateEncodingMenu];
        [self updateEncodingMenuTestedAgainst: bytes];
        NSArray * encodingIdentifiers = [[encodingMenu itemArray] valueForKey: @"representedObject"];
		
		unsigned long index = [encodingIdentifiers indexOfObject: [NSNumber numberWithUnsignedLong: guess]];
		int counter = 0;
		NSStringEncoding encoding;
		while(!testText)
		{
			encoding = [[encodingIdentifiers objectAtIndex: counter] unsignedLongValue];
			testText = [NSString stringWithCString: bytes encoding: encoding];
			index = counter++;
		}

        if(index != NSNotFound)
        {
            self.encodingSelection = index;
        }
        
        encodingTestString = bytes;
        [self testEncoding: self];
		guess = NSNotFound;
        if([NSApp runModalForWindow: encodingPanel] != NSCancelButton)
        {
            guess = [[[encodingMenu itemAtIndex: encodingSelection] representedObject] unsignedLongValue];
        }
        [encodingPanel close];
        [archive setNameEncoding: guess];
    }
    
    return guess;
}



- (IBAction)testEncoding:(id)sender
{
    NSMenuItem * encodingMenuItem = [encodingMenu itemAtIndex: encodingSelection];
    NSString * testText = [NSString stringWithCString: encodingTestString encoding: [[encodingMenuItem representedObject] unsignedLongValue]];
    
    if(!testText)
    {
        testText = @"invalid Selection";
    }
    
    [encodingTestField setStringValue: testText];
}



- (IBAction)actionStub:(id)sender
{
    
}



#pragma mark -
#pragma mark Bookmark Menu



//- (void)menuWillOpen:(NSMenu *)menu
//{
//	if([[menu title] isEqualToString: @"Bookmarks"])
//	{
//		[self buildBookmarkMenu];
//	}
//}


//- (void)buildHistoryMenu
//{
//	TSSTManagedBookmarkGroup * historyGroup = [self findBookmarkGroupWithIdentifier: @"history"];
//	
//	for(NSMenuItem * item in [historyMenu itemArray])
//	{
//		[historyMenu removeItem: item];
//	}
//	
//	NSArray * historyItems = [[historyGroup valueForKey: @"bookmarks"] allObjects];
//	NSMenuItem * menuItem;
//	for(TSSTManagedBookmark * historyItem in historyItems)
//	{
//		menuItem  = [historyMenu addItemWithTitle: [historyItem valueForKey: @"name"]
//										   action: @selector(openBookmarkFromMenu:)
//									keyEquivalent: @""];
//		[menuItem setRepresentedObject: historyItem];
//	}
//}
//
//
//
//- (void)buildBookmarkMenu
//{	
//	TSSTManagedBookmarkGroup * bookmarkGroup = [self findBookmarkGroupWithIdentifier: @"bookmarks"];
//	
//	for(NSMenuItem * item in [bookmarkMenu itemArray])
//	{
//		[bookmarkMenu removeItem: item];
//	}
//	
//	NSMenuItem * menuItem  = [bookmarkMenu addItemWithTitle: @"Bookmark This Page"  action: @selector(addBookmark:) keyEquivalent: @"b"];
//	menuItem = [bookmarkMenu addItemWithTitle: @"Bookmark Manager" action: @selector(showBookmarks:) keyEquivalent: @"B"];
//	[menuItem setTarget: bookmarkWindowController];
//	[bookmarkMenu addItem: [NSMenuItem separatorItem]];
//	
//	/* Call the recursive function that builds the menu. */
//	[self buildSubMenu: bookmarkMenu withNode: bookmarkGroup];
//}
//
//
//
//- (void)buildSubMenu:(NSMenu *)menu withNode:(TSSTManagedBookmarkGroup *)node
//{
//	TSSTManagedBookmarkGroup * bookmarkGroup;
//	NSArray * children = [[node valueForKey: @"children"] allObjects];
//	NSMenuItem * menuItem;
//	NSMenu * subMenu;
//	for(bookmarkGroup in children)
//	{
//		menuItem  = [menu addItemWithTitle: [bookmarkGroup valueForKey: @"name"]
//									action: nil
//							 keyEquivalent: @""];
//		subMenu = [NSMenu new];
//		[menu setSubmenu: subMenu  forItem: menuItem];
//		[subMenu release];
//		[self buildSubMenu: subMenu withNode: bookmarkGroup];
//	}
//	
//	NSArray * bookmarks = [[node valueForKey: @"bookmarks"] allObjects];
//	TSSTManagedBookmark * bookmark;
//	for(bookmark in bookmarks)
//	{
//		menuItem  = [menu addItemWithTitle: [bookmark valueForKey: @"name"]
//									action: @selector(openBookmarkFromMenu:)
//							 keyEquivalent: @""];
//		[menuItem setRepresentedObject: bookmark];
//	}
//}
//
//
//
//- (IBAction)openBookmarkFromMenu:(id)sender
//{
//	NSManagedObject * bookmark = [sender representedObject];
//	[bookmarkWindowController openBookmarkWithManagedObject: bookmark];
//}



@end


