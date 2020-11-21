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

	Simple Comic
	SimpleComicAppDelegate.m
*/

#import "SimpleComicAppDelegate.h"
#import <XADMaster/XADArchive.h>
#import "TSSTSessionWindowController.h"
#import "TSSTSortDescriptor.h"
#import "TSSTPage.h"
#import "TSSTManagedGroup.h"
#import "TSSTManagedSession.h"
#import "TSSTCustomValueTransformers.h"
#import "DTPreferencesController.h"
#import "Simple_Comic-Swift.h"
#import "TSSTManagedSession+CoreDataProperties.h"
#import <WebPMac/TSSTWebPImageRep.h>


@interface SimpleComicAppDelegate () <XADArchiveDelegate>

@end

NSString *const TSSTPageOrder =         @"pageOrder";
NSString *const TSSTPageScaleOptions =  @"scaleOptions";
NSString *const TSSTTwoPageSpread =     @"twoPageSpread";
NSString *const TSSTStatusbarVisible =  @"statusBarVisisble";
NSString *const TSSTBackgroundColor =   @"pageBackgroundColor";
NSString *const TSSTConstrainScale =    @"constrainScale";
NSString *const TSSTWindowAutoResize =  @"windowAutoResize";
NSString *const TSSTSessionRestore =    @"sessionRestore";
NSString *const TSSTEnableSwipe =       @"enableSwipe";
NSString *const TSSTLoupeDiameter =     @"loupeDiameter";
NSString *const TSSTLoupePower =        @"loupePower";

NSString *const TSSTLonelyFirstPage =   @"lonelyFirstPage";
NSString *const TSSTScrollersVisible =  @"scrollersVisible";
NSString *const TSSTPreserveModDate =   @"preserveModDate";
NSString *const TSSTUnifiedTitlebar =   @"unifiedTitlebar";
NSString *const TSSTFullscreenToolbar =   @"fullscreenToolbar";

NSString *const TSSTScrollPosition =    @"scrollPosition";
NSString *const TSSTZoomLevel =         @"zoomLevel";
NSString *const TSSTViewRotation =      @"rotation";
NSString *const TSSTSessionEndNotification = @"sessionEnd";

#pragma mark - String Encoding Functions



static NSArray<NSNumber*> * allAvailableStringEncodings(void)
{
	const CFStringEncoding encodings[] = {
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
        UINT_MAX
    };
    
	NSMutableArray * codeNumbers = [NSMutableArray arrayWithCapacity:sizeof(encodings) / sizeof(encodings[0]) - 1]; //We don't store the UINT_MAX value in the NSArray
	size_t counter = 0;
	NSStringEncoding encoding;
	while (encodings[counter] != UINT_MAX) {
		if (encodings[counter] != 101) {
			encoding = CFStringConvertEncodingToNSStringEncoding(encodings[counter]);
		} else {
			encoding = 101;
		}
		
		[codeNumbers addObject: @(encoding)];
		++counter;
	}
	
	return codeNumbers;
}


@implementation SimpleComicAppDelegate
{
	/*  This panel appears when the text encoding auto-detection fails */
	NSData					   * encodingTestData;
	NSInteger					 encodingSelection;
	
	/*  Core Data stuff. */
	NSManagedObjectModel		 * managedObjectModel;
	NSManagedObjectContext		 * managedObjectContext;
	NSPersistentStoreCoordinator * persistentStoreCoordinator;
	
	/** Auto-save timer */
	NSTimer * autoSave;
	
	/**  Window controller for preferences. */
	DTPreferencesController      * preferences;
	
	/**  This is the array that maintains all of the session window managers. */
	NSMutableArray<TSSTSessionWindowController*> * sessions;
	
	/*	Vars to delay the loading of files from an app launch until the core data store
	 has finished initializing */
	BOOL      launchInProgress;
	BOOL	  optionHeldAtlaunch;
	NSArray<NSString*>	*launchFiles;
}


@synthesize encodingSelection;
@synthesize passwordPanel;
@synthesize passwordField;
@synthesize encodingPanel;
@synthesize encodingTestField;
@synthesize encodingPopup;

+ (void)setMetadata:(NSString *)value forKey:(NSString *)key onStoreWithURL:(NSURL *)url managedBy:(NSPersistentStoreCoordinator *)coordinator
{
	NSPersistentStore * store = [coordinator persistentStoreForURL: url];
	NSMutableDictionary * metadata = [[coordinator metadataForPersistentStore: store] mutableCopy];
	[metadata setValue: value forKey: key];
	[coordinator setMetadata: metadata forPersistentStore: store];
}



/**  Sets up the user defaults and arrays of compatible file types. */
+ (void)initialize
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSDictionary* standardDefaults =
		@{
		  TSSTPageOrder: @YES,
		  TSSTPageScaleOptions: @1,
		  TSSTTwoPageSpread: @YES,
		  TSSTScrollersVisible: @YES,
		  TSSTBackgroundColor: [NSKeyedArchiver archivedDataWithRootObject: [NSColor whiteColor]],
		  TSSTConstrainScale: @YES,
		  TSSTWindowAutoResize: @YES,
		  TSSTSessionRestore: @YES,
		  TSSTEnableSwipe: @NO,
		  TSSTLoupeDiameter: @500,
		  TSSTLoupePower: @2.0f,
		  TSSTLonelyFirstPage: @YES,
		  TSSTStatusbarVisible: @YES,
		  TSSTPreserveModDate: @NO,
		  TSSTUnifiedTitlebar: @NO,
		  TSSTFullscreenToolbar: @NO,
		  };
		
		NSUserDefaultsController * sharedDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
		[sharedDefaultsController setInitialValues: standardDefaults];
		NSUserDefaults * defaults = [sharedDefaultsController defaults];
		[defaults registerDefaults: standardDefaults];
		NSData *colorData = [defaults dataForKey: TSSTBackgroundColor];
		// Convert old NSArchiver color key to NSKeyedArchiver, if needed
		if ([NSKeyedUnarchiver unarchiveObjectWithData: colorData] == nil) {
			NSColor *newColor = [NSUnarchiver unarchiveObjectWithData: colorData];
			if (newColor && [newColor isKindOfClass: [NSColor class]]) {
				NSData *newKey = [NSKeyedArchiver archivedDataWithRootObject: newColor];
				[defaults setObject: newKey forKey: TSSTBackgroundColor];
			} else {
				//shrug
				[defaults removeObjectForKey: TSSTBackgroundColor];
			}
		}
		
		id transformer = [TSSTLastPathComponent new];
		[NSValueTransformer setValueTransformer: transformer forName: @"TSSTLastPathComponent"];
	});
}


- (void) dealloc
{
	[[NSUserDefaults standardUserDefaults] removeObserver: self forKeyPath: TSSTSessionRestore];
}


#pragma mark - Application Delegate Methods


/**	Stores any files that were opened on launch till applicationDidFinishLaunching:
	is called. */
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	autoSave = nil;
	launchFiles = nil;
	launchInProgress = YES;
	preferences = nil;
	optionHeldAtlaunch = NO;
	if (![NSImageRep imageRepClassForType:@"public.webp"]) {
		[NSImageRep registerImageRepClass:[TSSTWebPImageRep class]];
	}
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endSession:) name: TSSTSessionEndNotification object: nil];
	[[NSUserDefaults standardUserDefaults] addObserver: self forKeyPath: TSSTSessionRestore options: 0 context: nil];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	[self generateEncodingMenu];
	
	/* Starts the auto save timer */
	if([userDefaults boolForKey: TSSTSessionRestore])
	{
		autoSave = [NSTimer scheduledTimerWithTimeInterval: 30.0 target: self selector: @selector(saveContext) userInfo: nil repeats: YES];
	}
	sessions = [NSMutableArray new];
	@try {
		[self sessionRelaunch];
	} @catch(NSException *e) {
		NSLog(@"%@", e);
	}
	launchInProgress = NO;
	
	if (launchFiles) {
		TSSTManagedSession * session;
		if (!optionHeldAtlaunch)
		{
			NSMutableArray * looseImages = [NSMutableArray array];
			for(NSString * path in launchFiles)
			{
				if([[TSSTManagedArchive archiveExtensions] containsObject: [[path pathExtension] lowercaseString]])
				{
					session = [self newSessionWithFiles: @[path]];
					[self windowForSession: session];
				}
				else {
					[looseImages addObject: path];
				}
			}
			
			if ([looseImages count]> 0) {
				session = [self newSessionWithFiles: looseImages];
				[self windowForSession: session];
			}
		}
		else
		{
			session = [self newSessionWithFiles: launchFiles];
			[self windowForSession: session];
		}
		
		launchFiles = nil;
	}
}


- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	
	if(![userDefaults boolForKey: TSSTSessionRestore])
	{
		/* Goes through and deletes all active sessions if the user has auto save turned off */
		for(TSSTSessionWindowController * sessionWindow in sessions)
		{
			[[sessionWindow window] performClose: self];
		}
	}
	
	NSApplicationTerminateReply reply = NSTerminateNow;
	
	/* TODO: some day I really need to add the fallback error handling */
	if(![self saveContext])
	{
		// Error handling wasn't implemented. Fall back to displaying a "quit anyway" panel.
		NSAlert *alert = [NSAlert new];
		alert.messageText = NSLocalizedString(@"Quit without saving session?", @"");
		alert.informativeText = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"");
		[alert addButtonWithTitle:NSLocalizedString(@"Quit anyway", @"")];
		[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
		NSInteger alertReturn = [alert runModal];
		if (alertReturn == NSAlertSecondButtonReturn)
		{
			reply = NSTerminateCancel;
		}
	}
	
	return reply;
}


- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
	return [[self managedObjectContext] undoManager];
}


/** Used to watch and react to pref changes */
- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context
{
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	
	if([keyPath isEqualToString: TSSTSessionRestore])
	{
		[autoSave invalidate];
		autoSave = nil;
		if([userDefaults boolForKey: TSSTSessionRestore])
		{
			autoSave = [NSTimer scheduledTimerWithTimeInterval: 30.0 target: self selector: @selector(saveContext) userInfo: nil repeats: YES];
		}
	}
}


- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
	BOOL option = ([NSEvent modifierFlags] & (NSEventModifierFlagOption)) != 0;
	if(!launchInProgress)
	{
		TSSTManagedSession * session;
		if (!option)
		{
			NSMutableArray * looseImages = [NSMutableArray array];
			for(NSString * path in filenames)
			{
				if([[TSSTManagedArchive archiveExtensions] containsObject: [[path pathExtension] lowercaseString]])
				{
					session = [self newSessionWithFiles: @[path]];
					[self windowForSession: session];
				}
				else
				{
					[looseImages addObject: path];
				}
			}
			
			if ([looseImages count]> 0) {
				session = [self newSessionWithFiles: looseImages];
				[self windowForSession: session];
			}
		}
		else
		{
			session = [self newSessionWithFiles: filenames];
			[self windowForSession: session];
		}
	}
	else
	{
		launchFiles = filenames;
		optionHeldAtlaunch = option;
	}
}


#pragma mark - Core Data


- (NSManagedObjectModel *)managedObjectModel
{
	if (managedObjectModel != nil) {
		return managedObjectModel;
	}
	
	managedObjectModel = [NSManagedObjectModel mergedModelFromBundles: nil];
	return managedObjectModel;
}


/**	Returns the persistent store coordinator for the application.  This
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
	
	NSDictionary * storeOptions = @{NSMigratePersistentStoresAutomaticallyOption: @YES,
									NSPersistentStoreOSCompatibility: @(MAC_OS_X_VERSION_10_9)};
	url = [[NSURL fileURLWithPath:applicationSupportFolder] URLByAppendingPathComponent: @"SimpleComic.sql"];
	
	error = nil;
	NSDictionary * storeInfo = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType: NSSQLiteStoreType URL: url options:@{} error: &error];
	if(error)
	{
		NSLog(@"%@",[error localizedDescription]);
	}
	
	if(![[storeInfo valueForKey: @"viewVersion"] isEqualToString: @"Version 1708"])
	{
		if(![fileManager removeItemAtURL: url error: &error])
		{
			NSLog(@"%@",[error localizedDescription]);
		}
	}
	
	persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
	
	if (![persistentStoreCoordinator addPersistentStoreWithType: NSSQLiteStoreType configuration: nil URL: url options: storeOptions error: &error])
	{
		[[NSApplication sharedApplication] presentError: error];
	}
	
	[SimpleComicAppDelegate setMetadata: @"Version 1708" forKey: @"viewVersion" onStoreWithURL: url managedBy: persistentStoreCoordinator];
	
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
		managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
		[managedObjectContext setPersistentStoreCoordinator: coordinator];
	}
	
	return managedObjectContext;
}


/**  Method creates an application support directory for Simple Comic if one
    does not already exist.
    @return The absolute path to Simple Comic's application support directory
	as a string.  */
- (NSString *)applicationSupportFolder
{
	NSArray * paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSString * basePath = paths.firstObject ?: NSTemporaryDirectory();
	return [basePath stringByAppendingPathComponent: @"Simple Comic"];
}

- (BOOL)saveContext
{
	for (TSSTSessionWindowController * controller in sessions)
	{
		[controller updateSessionObject];
	}
	
	NSManagedObjectContext *context = self.managedObjectContext;
	__block BOOL saved = YES;
	[context performBlockAndWait:^{
		if (![context commitEditing]) {
			NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
		}
		
		NSError *error = nil;
		if (context.hasChanges && ![context save:&error]) {
			[[NSApplication sharedApplication] presentError:error];
			saved = NO;
		} else {
			saved = YES;
		}
	}];
	
	return saved;
}

#pragma mark - Session Managment

- (void)windowForSession:(TSSTManagedSession *)settings
{
	NSArray * existingSessions = [sessions valueForKey: @"session"];
	if([settings.images count] > 0 && ![existingSessions containsObject: settings])
	{
		TSSTSessionWindowController * comicWindow = [[TSSTSessionWindowController alloc] initWithSession: settings];
		[sessions addObject: comicWindow];
		[comicWindow showWindow: self];
	}
}

- (void)endSession:(NSNotification *)notification
{
	TSSTSessionWindowController * controller = [notification object];
	TSSTManagedSession * sessionToRemove = [controller session];
	[sessions removeObject: controller];
	[[self managedObjectContext] deleteObject: sessionToRemove];
}

- (void)sessionRelaunch
{
	TSSTManagedSession * session;
	NSFetchRequest * sessionRequest = [TSSTManagedSession fetchRequest];
	NSError * fetchError;
	NSArray * managedSessions = [[self managedObjectContext] executeFetchRequest: sessionRequest error: &fetchError];
	for(session in managedSessions)
	{
		if([session.groups count] <= 0)
		{
			[[self managedObjectContext] deleteObject: session];
		}
		else
		{
			[self windowForSession: session];
		}
	}
}

- (TSSTManagedSession *)newSessionWithFiles:(NSArray<NSString*> *)files
{
	NSMutableArray<NSURL*> *array = [[NSMutableArray alloc] initWithCapacity:files.count];
	for (NSString *path in files) {
		[array addObject:[NSURL fileURLWithPath:path]];
	}
	return [self newSessionWithFileURLs:array];
}

- (TSSTManagedSession *)newSessionWithFileURLs:(NSArray<NSURL*> *)files
{
	TSSTManagedSession * sessionDescription = [NSEntityDescription insertNewObjectForEntityForName: @"Session" inManagedObjectContext: [self managedObjectContext]];
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	
	sessionDescription.scaleOptions = [defaults integerForKey: TSSTPageScaleOptions];
	sessionDescription.pageOrder = [defaults boolForKey: TSSTPageOrder];
	sessionDescription.twoPageSpread = [defaults boolForKey: TSSTTwoPageSpread];
	
	[self addFileURLs: files toSession: sessionDescription];
	
	return sessionDescription;
}


- (void)addFileURLs:(NSArray<NSURL*> *)paths toSession:(TSSTManagedSession *)session
{
	[[self managedObjectContext] performBlockAndWait:^{
		NSFileManager * fileManager = [NSFileManager defaultManager];
		BOOL isDirectory;
		NSMutableSet<TSSTPage *> * pageSet = [session.images mutableCopy];
		for (NSURL *path in paths)
		{
			NSString *fileExtension = [[path pathExtension] lowercaseString];
			BOOL exists = [fileManager fileExistsAtPath: path.path isDirectory: &isDirectory];
			if(exists && ![[[path lastPathComponent] substringToIndex: 1] isEqualToString: @"."])
			{
				TSSTPage * fileDescription = nil;
				TSSTManagedGroup* mgroup;
				if(isDirectory)
				{
					mgroup = [NSEntityDescription insertNewObjectForEntityForName: @"ImageGroup" inManagedObjectContext: [self managedObjectContext]];
					mgroup.fileURL = path;
					mgroup.name = path.lastPathComponent;
					[mgroup nestedFolderContents];
				}
				else if([[TSSTManagedArchive archiveExtensions] containsObject: fileExtension])
				{
					mgroup = [NSEntityDescription insertNewObjectForEntityForName: @"Archive" inManagedObjectContext: [self managedObjectContext]];
					mgroup.fileURL = path;
					mgroup.name = path.lastPathComponent;
					[(TSSTManagedArchive *)mgroup nestedArchiveContents];
				}
				else if([fileExtension compare:@"pdf" options:NSCaseInsensitiveSearch] == NSOrderedSame)
				{
					mgroup = [NSEntityDescription insertNewObjectForEntityForName: @"PDF" inManagedObjectContext: [self managedObjectContext]];
					mgroup.fileURL = path;
					mgroup.name = path.lastPathComponent;
					[(TSSTManagedPDF *)mgroup pdfContents];
				}
				else if([[TSSTPage imageExtensions] containsObject: fileExtension] || [[TSSTPage textExtensions] containsObject: fileExtension])
				{
					fileDescription = [NSEntityDescription insertNewObjectForEntityForName: @"Image" inManagedObjectContext: [self managedObjectContext]];
					[fileDescription setValue: path.path forKey: @"imagePath"];
				}
				
				if(mgroup)
				{
					[pageSet unionSet: mgroup.nestedImages];
					mgroup.session = session;
				}
				else if (fileDescription)
				{
					[pageSet addObject: fileDescription];
				}
				
				if(fileDescription || mgroup)
				{
					[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL: path];
				}
			}
		}
		
		session.images = pageSet;
	}];
}

#pragma mark - Actions

// Launches open modal.
- (IBAction)addPages:(id)sender
{
	// Creates a new modal.
	NSOpenPanel * addPagesModal = [NSOpenPanel openPanel];
	[addPagesModal setAllowsMultipleSelection: YES];
	[addPagesModal setCanChooseDirectories: YES];
	
	NSMutableArray * allAllowedFileTypes = [[TSSTManagedArchive archiveTypes] mutableCopy];
	[allAllowedFileTypes addObjectsFromArray: [TSSTPage imageTypes]];
	[allAllowedFileTypes addObject:(NSString*)kUTTypePDF];
	[addPagesModal setAllowedFileTypes:allAllowedFileTypes];
	
	if([addPagesModal runModal] !=  NSModalResponseCancel)
	{
		NSArray<NSURL*> *fileURLs = [addPagesModal URLs];
		
		TSSTManagedSession * session = [self newSessionWithFileURLs: fileURLs];
		[self windowForSession: session];
	}
}

- (IBAction)modalOK:(id)sender
{
	[NSApp stopModalWithCode: NSModalResponseOK];
}

- (IBAction)modalCancel:(id)sender
{
	[NSApp stopModalWithCode: NSModalResponseCancel];
}

- (IBAction)openPreferences:(id)sender
{
	if(!preferences)
	{
		preferences = [DTPreferencesController new];
	}
	[preferences showWindow: self];
}

#pragma mark - Archive Encoding Handling

- (IBAction)testEncodingMenu:(id)sender
{
	[NSApp runModalForWindow: encodingPanel];
}

- (void)generateEncodingMenu
{
	NSMenu * encodingMenu = [encodingPopup menu];
	NSArray * allEncodings = allAvailableStringEncodings();
	self.encodingSelection = 0;
	[encodingMenu setAutoenablesItems: NO];
	for (NSMenuItem * encodingMenuItem in [encodingMenu itemArray]) {
		[encodingMenu removeItem: encodingMenuItem];
	}
	
	for (NSNumber *encodingIdent in allEncodings) {
		NSStringEncoding stringEncoding = [encodingIdent unsignedIntegerValue];
		NSString * encodingName = [NSString localizedNameOfStringEncoding: stringEncoding];
		if (stringEncoding == 101) {
			[encodingMenu addItem: [NSMenuItem separatorItem]];
		} else if (encodingName && ![encodingName isEqualToString: @""]) {
			NSMenuItem * encodingMenuItem = [[NSMenuItem alloc] initWithTitle: encodingName action: nil keyEquivalent: @""];
			[encodingMenuItem setRepresentedObject: encodingIdent];
			[encodingMenu addItem: encodingMenuItem];
		}
	}
	[encodingPopup bind: @"selectedIndex" toObject: self withKeyPath: @"encodingSelection" options: nil];
}

- (void)updateEncodingMenuTestedAgainst:(NSData *)data
{
	for (NSMenuItem * encodingMenuItem in [[encodingPopup menu] itemArray]) {
		NSStringEncoding stringEncoding = [[encodingMenuItem representedObject] unsignedIntegerValue];
		[encodingMenuItem setEnabled: NO];
		if (![encodingMenuItem isSeparatorItem]) {
			NSString * testText = [[NSString alloc] initWithData: data encoding: stringEncoding];
			
			[encodingMenuItem setEnabled: testText ? YES : NO];
		}
	}
}

- (NSString*)passwordForArchiveWithPath:(NSString*)filename
{
	NSString* password = nil;
	[passwordField setStringValue: @""];
	if([NSApp runModalForWindow: passwordPanel] != NSModalResponseCancel)
	{
		password = [passwordField stringValue];
	}
	
	[passwordPanel close];
	return password;
}

- (NSStringEncoding)archive:(XADArchive *)archive
			encodingForData:(NSData *)data
					  guess:(NSStringEncoding)guess
				 confidence:(float)confidence
{
	NSString * testText = [[NSString alloc] initWithData: data encoding: guess];
	if (confidence < 0.8 || !testText) {
		NSMenu * encodingMenu = [encodingPopup menu];
		[self updateEncodingMenuTestedAgainst: data];
		NSArray * encodingIdentifiers = [[encodingMenu itemArray] valueForKey: @"representedObject"];
		
		NSUInteger index = [encodingIdentifiers indexOfObject: @(guess)];
		NSUInteger counter = 0;
		NSNumber * encoding;
		while (!testText) {
			encoding = encodingIdentifiers[counter];
			if ([encoding class] != [NSNull class])
			{
				testText = [[NSString alloc] initWithData: data encoding: [encoding unsignedIntegerValue]];
			}
			index = counter++;
		}
		
		if (index != NSNotFound) {
			self.encodingSelection = index;
		}
		
		encodingTestData = data;
		
		[self testEncoding: self];
		guess = NSNotFound;
		if([NSApp runModalForWindow: encodingPanel] != NSModalResponseCancel)
		{
			guess = [[[encodingMenu itemAtIndex: encodingSelection] representedObject] unsignedIntegerValue];
		}
		[encodingPanel close];
		[archive setNameEncoding: guess];
	}
	
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
}

@end
