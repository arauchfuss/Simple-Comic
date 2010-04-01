#import "SS_PrefsController.h"
#import "SS_PreferencePaneProtocol.h"


@interface SS_PrefsController (PRIVATE)
- (id)initWithPanes:(NSArray *)inArray delegate:(id)inDelegate;
@end

@implementation SS_PrefsController

#define Last_Pane_Defaults_Key	[[[NSBundle mainBundle] bundleIdentifier] stringByAppendingString:@"_Preferences_Last_Pane_Defaults_Key"]

// ************************************************
// version/init/dealloc/constructors
// ************************************************


+ (NSInteger)version
{
    return 1; // 28th June 2003
}


+ (id)preferencesWithPanesSearchPath:(NSString*)path bundleExtension:(NSString *)ext
{
    return [[[SS_PrefsController alloc] initWithPanesSearchPath:path bundleExtension:ext] autorelease];
}


+ (id)preferencesWithBundleExtension:(NSString *)ext
{
    return [[[SS_PrefsController alloc] initWithBundleExtension:ext] autorelease];
}


+ (id)preferencesWithPanesSearchPath:(NSString*)path
{
    return [[[SS_PrefsController alloc] initWithPanesSearchPath:path] autorelease];
}


+ (id)preferences
{
    return [[[SS_PrefsController alloc] init] autorelease];
}

+ (id)preferencesWithPanes:(NSArray *)inArray delegate:(id)inDelegate
{
	return [[[SS_PrefsController alloc] initWithPanes:inArray delegate:inDelegate] autorelease];
}

- (id)initWithPanesSearchPath:(NSString*)path
{
    return [self initWithPanesSearchPath:path bundleExtension:nil];
}


- (id)initWithBundleExtension:(NSString *)ext
{
    return [self initWithPanesSearchPath:nil bundleExtension:ext];
}

- (id)init
{
	if ((self = [super init])) {
		[self setDebug:NO];
        preferencePanes = [[NSMutableDictionary alloc] init];
        panesOrder = [[NSMutableArray alloc] init];
        
        [self setToolbarDisplayMode:NSToolbarDisplayModeIconAndLabel];
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_2
        [self setToolbarSizeMode:NSToolbarSizeModeDefault];
#endif
        [self setUsesTexturedWindow:NO];
        [self setAlwaysShowsToolbar:NO];
        [self setAlwaysOpensCentered:YES];		
	}
	
	return self;
}

// Designated initializer
- (id)initWithPanesSearchPath:(NSString*)path bundleExtension:(NSString *)ext
{
    if ((self = [self init])) {
        if (!ext || [ext isEqualToString:@""]) {
            bundleExtension = [[NSString alloc] initWithString:@"preferencePane"];
        } else {
            bundleExtension = [ext retain];
        }
        
        if (!path || [path isEqualToString:@""]) {
            searchPath = [[NSString alloc] initWithString:[[NSBundle mainBundle] resourcePath]];
        } else {
            searchPath = [path retain];
        }
        
        // Read PreferencePanes
        if (searchPath) {
            NSEnumerator* enumerator = [[NSBundle pathsForResourcesOfType:bundleExtension inDirectory:searchPath] objectEnumerator];
            NSString* panePath;
            while ((panePath = [enumerator nextObject])) {
                [self activatePane:panePath];
            }
        }
        return self;
    }
    return nil;
}

- (id)initWithPanes:(NSArray *)inArray delegate:(id)inDelegate
{
	if ((self = [self init])) {
		NSEnumerator *enumerator = [inArray objectEnumerator];
		id <SS_PreferencePaneProtocol> aPane;
		
		while ((aPane = [enumerator nextObject])) {
			[panesOrder addObject:[aPane paneIdentifier]];
			[preferencePanes setObject:aPane forKey:[aPane paneIdentifier]];
		}
		
		delegate = inDelegate;
	}
	
	return self;
}

- (void)dealloc
{
	[prefsWindow close];
	prefsWindow = nil;
	[prefsToolbar release];
	[prefsToolbarItems release];
	[preferencePanes release];
	[panesOrder release];
	[bundleExtension release];
	[searchPath release];

    [super dealloc];
}


// ************************************************
// Preferences methods
// ************************************************


- (void)showPreferencesWindow
{
    [self createPreferencesWindowAndDisplay:YES];
}


- (void)createPreferencesWindow
{
    [self createPreferencesWindowAndDisplay:YES];
}


- (void)sizeWindowForToolbar
{
	NSToolbar	*windowToolbar = [prefsWindow toolbar];
	NSRect		windowFrame = [prefsWindow frame];
	
	while ([[windowToolbar visibleItems] count] < [[windowToolbar items] count]) {
		//Each toolbar item is 32x32; we expand by one toolbar item width repeatedly until they all fit
		windowFrame.origin.x -= 16;
		windowFrame.size.width += 16;
		
		[prefsWindow setFrame:windowFrame display:NO];
	}
	minimumWidthForToolbar = windowFrame.size.width;

	[prefsWindow displayIfNeeded];
}


- (void)createPreferencesWindowAndDisplay:(BOOL)shouldDisplay
{
    if (prefsWindow) {
        if (alwaysOpensCentered && ![prefsWindow isVisible]) {
            [prefsWindow center];
        }
        [prefsWindow makeKeyAndOrderFront:nil];
        return;
    }
    
    // Create prefs window
    unsigned int styleMask = (NSClosableWindowMask | NSTitledWindowMask );

    prefsWindow = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, 150, 200)
                                              styleMask:styleMask
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    [prefsWindow setDelegate:self];
    [prefsWindow setReleasedWhenClosed: YES];
    [prefsWindow setTitle:@"Preferences"]; // initial default title

    [self createPrefsToolbar];
	[self sizeWindowForToolbar];
    [prefsWindow center];

    // Register defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (panesOrder && ([panesOrder count] > 0)) {
        NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
        [defaultValues setObject:[panesOrder objectAtIndex:0] forKey:Last_Pane_Defaults_Key];
        [defaults registerDefaults:defaultValues];
    }
    
    // Load last view
    NSString *lastViewName = [defaults objectForKey:Last_Pane_Defaults_Key];
    
    if ([panesOrder containsObject:lastViewName] && [self loadPrefsWithIdentifier:lastViewName display:NO]) {
        if (shouldDisplay) {
            [prefsWindow makeKeyAndOrderFront:nil];
        }
		[prefsToolbar setSelectedItemIdentifier:lastViewName];
        return;
    }

    [self debugLog:[NSString stringWithFormat:@"Could not load last-used preference pane \"%@\". Trying to load another pane instead.", lastViewName]];
    
    // Try to load each prefpane in turn if loading the last-viewed one fails.
    NSEnumerator* panes = [panesOrder objectEnumerator];
    NSString *pane;
    while ((pane = [panes nextObject])) {
        if (![pane isEqualToString:lastViewName]) {
            if ([self loadPrefsWithIdentifier:pane display:NO]) {
                if (shouldDisplay) {
                    [prefsWindow makeKeyAndOrderFront:nil];
                }
				[prefsToolbar setSelectedItemIdentifier:pane];
                return;
            }
        }
    }

    [self debugLog:[NSString stringWithFormat:@"Could not load any valid preference panes. The preference pane bundle extension was \"%@\" and the search path was: %@", bundleExtension, searchPath]];
    
    // Show alert dialog.
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    NSRunAlertPanel(@"Preferences",
                    [NSString stringWithFormat:@"Preferences are not available for %@.", appName],
                    @"OK",
                    nil,
                    nil);
    [prefsWindow close];
    prefsWindow = nil;
}


- (void)destroyPreferencesWindow
{
	[prefsWindow close];
    prefsWindow = nil;
}


- (void)windowWillClose:(NSNotification *)aNotification
{
	//Don't continue to work with prefsWindow
	prefsWindow = nil;

	//Let the preference panes know we're closing	
//	[[preferencePanes allValues] makeObjectsPerformSelector:@selector(closeView)];
	if([[NSColorPanel sharedColorPanel] isVisible])
	{
		[[NSColorPanel sharedColorPanel] close];
	}
	
	//Tell the delegate
	if ([delegate respondsToSelector:@selector(prefsWindowWillClose:)]) {
		[delegate prefsWindowWillClose:self];		
	}
}



- (void)activatePane:(NSString*)path {
    NSBundle* paneBundle = [NSBundle bundleWithPath:path];
    if (paneBundle) {
        NSDictionary* paneDict = [paneBundle infoDictionary];
        NSString* paneName = [paneDict objectForKey:@"NSPrincipalClass"];
        if (paneName) {
            Class paneClass = NSClassFromString(paneName);
            if (!paneClass) {
                paneClass = [paneBundle principalClass];
                if ([paneClass conformsToProtocol:@protocol(SS_PreferencePaneProtocol)] && [paneClass isKindOfClass:[NSObject class]]) {
                    NSArray *panes = [paneClass preferencePanes];
                    
                    NSEnumerator *enumerator = [panes objectEnumerator];
                    id <SS_PreferencePaneProtocol> aPane;
                    
                    while ((aPane = [enumerator nextObject])) {
                        [panesOrder addObject:[aPane paneIdentifier]];
                        [preferencePanes setObject:aPane forKey:[aPane paneIdentifier]];
                    }
                } else {
                    [self debugLog:[NSString stringWithFormat:@"Did not load bundle: %@ because its Principal Class is either not an NSObject subclass, or does not conform to the PreferencePane Protocol.", paneBundle]];
                }
            } else {
                [self debugLog:[NSString stringWithFormat:@"Did not load bundle: %@ because its Principal Class was already used in another Preference pane.", paneBundle]];
            }
        } else {
            [self debugLog:[NSString stringWithFormat:@"Could not obtain name of Principal Class for bundle: %@", paneBundle]];
        }
    } else {
        [self debugLog:[NSString stringWithFormat:@"Could not initialize bundle: %@", paneBundle]];
    }
}


- (BOOL)loadPreferencePaneNamed:(NSString *)name
{
    return [self loadPrefsWithIdentifier:name display:YES];
}


- (NSArray *)loadedPanes
{
    if (preferencePanes) {
        return [preferencePanes allKeys];
    }
    return nil;
}


- (BOOL)loadPrefsWithIdentifier:(NSString *)name display:(BOOL)disp
{
    if (!prefsWindow) {
        NSBeep();
        [self debugLog:[NSString stringWithFormat:@"Could not load \"%@\" preference pane because the Preferences window seems to no longer exist.", name]];
        return NO;
    }

    id tempPane = nil;
    tempPane = [preferencePanes objectForKey:name];
    if (!tempPane) {
        [self debugLog:[NSString stringWithFormat:@"Could not load preference pane \"%@\", because that pane does not exist.", name]];
        return NO;
    }
    
    NSView *prefsView = nil;
    prefsView = [tempPane paneView];
    if (!prefsView) {
        [self debugLog:[NSString stringWithFormat:@"Could not load \"%@\" preference pane because its view could not be loaded from the bundle.", name]];
        return NO;
    }
    
    // Get rid of old view before resizing, for display purposes.
    if (disp) {
		//Clear the first responder to make sure any changes are saved
		[prefsWindow makeFirstResponder:nil];

        NSView *tempView = [[NSView alloc] initWithFrame:[[prefsWindow contentView] frame]];
        [prefsWindow setContentView:tempView];
        [tempView release]; 
    }
    
    // Preserve upper left point of window during resize.
    NSRect newFrame = [prefsWindow frame];
    newFrame.size.height = [prefsView frame].size.height + ([prefsWindow frame].size.height - [[prefsWindow contentView] frame].size.height);
    newFrame.size.width = [prefsView frame].size.width;
	//Ensure the full toolbar still fits
	if (newFrame.size.width < minimumWidthForToolbar) newFrame.size.width =  minimumWidthForToolbar;
    newFrame.origin.y += ([[prefsWindow contentView] frame].size.height - [prefsView frame].size.height);
    
    id <SS_PreferencePaneProtocol> pane = [preferencePanes objectForKey:name];
    [prefsWindow setShowsResizeIndicator:([pane allowsHorizontalResizing] || [pane allowsHorizontalResizing])];
    
    [prefsWindow setFrame:newFrame display:disp animate:disp];
    
    [prefsWindow setContentView:prefsView];
    
    // Set appropriate resizing on window.
    NSSize theSize = [prefsWindow frame].size;
    theSize.height -= ToolbarHeightForWindow(prefsWindow);
    [prefsWindow setMinSize:theSize];
    
    BOOL canResize = NO;
    if ([pane allowsHorizontalResizing]) {
        theSize.width = FLT_MAX;
        canResize = YES;
    }
    if ([pane allowsVerticalResizing]) {
        theSize.height = FLT_MAX;
        canResize = YES;
    }
    [prefsWindow setMaxSize:theSize];
    [prefsWindow setShowsResizeIndicator:canResize];

    if ((prefsToolbarItems && ([prefsToolbarItems count] > 1)) || alwaysShowsToolbar) {
        [prefsWindow setTitle:[pane paneName]];
		[[prefsWindow toolbar] setSelectedItemIdentifier:name];
    }
    
    // Update defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:name forKey:Last_Pane_Defaults_Key];
    
	//Disable the zoom button
    [[prefsWindow standardWindowButton:NSWindowZoomButton] setEnabled:NO];

    return YES;
}


- (void)debugLog:(NSString*)msg
{
//    if (debug) {
        NSLog(@"[--- PREFERENCES DEBUG MESSAGE ---]\r%@\r\r", msg);
//    }
}


// ************************************************
// Prefs Toolbar methods
// ************************************************


float ToolbarHeightForWindow(NSWindow *window)
{
    NSToolbar *toolbar;
    float toolbarHeight = 0.0;
    NSRect windowFrame;
    
    toolbar = [window toolbar];
    
    if(toolbar && [toolbar isVisible])
    {
        windowFrame = [NSWindow contentRectForFrameRect:[window frame]
                                              styleMask:[window styleMask]];
        toolbarHeight = NSHeight(windowFrame)
            - NSHeight([[window contentView] frame]);
    }

    return toolbarHeight;
}


- (void)createPrefsToolbar
{
    // Create toolbar items
    prefsToolbarItems = [[NSMutableDictionary alloc] init];
    NSEnumerator *itemEnumerator = [panesOrder objectEnumerator];
    NSString *identifier;
    NSImage *itemImage;
    
    while ((identifier = [itemEnumerator nextObject])) {
        if ([preferencePanes objectForKey:identifier] != nil) {
			NSObject<SS_PreferencePaneProtocol> *pane = [preferencePanes objectForKey:identifier];
			
			NSString	 *paneName = [pane paneName];
            NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];
            [item setPaletteLabel:paneName]; // item's label in the "Customize Toolbar" sheet (not relevant here, but we set it anyway)
            [item setLabel:paneName]; // item's label in the toolbar
            NSString *tempTip = [pane paneToolTip];
            if (!tempTip || [tempTip isEqualToString:@""]) {
                [item setToolTip:nil];
            } else {
                [item setToolTip:tempTip];
            }
            itemImage = [pane paneIcon];
            [item setImage:itemImage];
            
            [item setTarget:self];
            [item setAction:@selector(prefsToolbarItemClicked:)]; // action called when item is clicked
            [prefsToolbarItems setObject:item forKey:identifier]; // add to items
            [item release];
        } else if ([identifier isEqual:NSToolbarSeparatorItemIdentifier]) {
			//Don't have to do anything
		} else {
            [self debugLog:[NSString stringWithFormat:@"Could not create toolbar item for preference pane \"%@\", because that pane does not exist.", identifier]];
        }
    }
    
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    prefsToolbar = [[NSToolbar alloc] initWithIdentifier:[bundleIdentifier stringByAppendingString:@"_Preferences_Toolbar_Identifier"]];
    [prefsToolbar setDelegate:self];
    [prefsToolbar setAllowsUserCustomization:NO];
    [prefsToolbar setAutosavesConfiguration:NO];
    [prefsToolbar setDisplayMode:toolbarDisplayMode];
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_2
    [prefsToolbar setSizeMode:toolbarSizeMode];
#endif
    if ((prefsToolbarItems && ([prefsToolbarItems count] > 1)) || alwaysShowsToolbar) {
        [prefsWindow setToolbar:prefsToolbar];
    } else if (!alwaysShowsToolbar && prefsToolbarItems && ([prefsToolbarItems count] == 1)) {
        [self debugLog:@"Not showing toolbar in Preferences window because there is only one preference pane loaded. You can override this behaviour using -[setAlwaysShowsToolbar:YES]."];
    }
	
	//Hide the toolbar button
	[[prefsWindow standardWindowButton:NSWindowToolbarButton] setFrame:NSZeroRect];
}


- (NSToolbarDisplayMode)toolbarDisplayMode
{
    return toolbarDisplayMode;
}


- (void)setToolbarDisplayMode:(NSToolbarDisplayMode)displayMode
{
    toolbarDisplayMode = displayMode;
}


#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_2
- (NSToolbarSizeMode)toolbarSizeMode
{
    return toolbarSizeMode;
}


- (void)setToolbarSizeMode:(NSToolbarSizeMode)sizeMode
{
    toolbarSizeMode = sizeMode;
}
#endif


- (void)prefsToolbarItemClicked:(NSToolbarItem*)item
{
    if (![[item itemIdentifier] isEqualToString:[prefsWindow title]]) {
        [self loadPrefsWithIdentifier:[item itemIdentifier] display:YES];
    }
}


- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return panesOrder;
}


- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return panesOrder;
}


- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    return [prefsToolbarItems objectForKey:itemIdentifier];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
    return panesOrder;
}

/*!
 * @brief Disable toolbar customization
 *
 * Used by AIInterfaceController to validate the customize toolbar menu item
 */
- (BOOL)canCustomizeToolbar
{
	return NO;
}

// ************************************************
// Accessors
// ************************************************


- (NSWindow *)preferencesWindow
{
    return prefsWindow;
}


- (NSString *)bundleExtension
{
    return bundleExtension;
}


- (NSString *)searchPath
{
    return searchPath;
}


- (NSArray *)panesOrder
{
    return panesOrder;
}


- (void)setPanesOrder:(NSArray *)newPanesOrder
{
    [panesOrder removeAllObjects];

    NSEnumerator *enumerator = [newPanesOrder objectEnumerator];
    NSString *name;
    
    while ((name = [enumerator nextObject])) {
        if (([preferencePanes objectForKey:name] != nil) ||
			([name isEqual:NSToolbarSeparatorItemIdentifier])) {
            [panesOrder addObject:name];
        } else {
            [self debugLog:[NSString stringWithFormat:@"Did not add preference pane \"%@\" to the toolbar ordering array, because that pane does not exist.", name]];
        }
    }
}


- (BOOL)debug
{
    return debug;
}


- (void)setDebug:(BOOL)newDebug
{
    debug = newDebug;
}


- (BOOL)usesTexturedWindow
{
    return usesTexturedWindow;
}


- (void)setUsesTexturedWindow:(BOOL)newUsesTexturedWindow
{
    usesTexturedWindow = newUsesTexturedWindow;
}


- (BOOL)alwaysShowsToolbar
{
    return alwaysShowsToolbar;
}


- (void)setAlwaysShowsToolbar:(BOOL)newAlwaysShowsToolbar
{
    alwaysShowsToolbar = newAlwaysShowsToolbar;
}


- (BOOL)alwaysOpensCentered
{
    return alwaysOpensCentered;
}


- (void)setAlwaysOpensCentered:(BOOL)newAlwaysOpensCentered
{
    alwaysOpensCentered = newAlwaysOpensCentered;
}

@end
