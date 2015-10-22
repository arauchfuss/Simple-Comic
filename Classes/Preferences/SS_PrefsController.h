/* SS_PrefsController */

#import <Cocoa/Cocoa.h>

@interface SS_PrefsController : NSObject <NSWindowDelegate, NSToolbarDelegate>
{
    NSWindow *prefsWindow;
    NSMutableDictionary *preferencePanes;
    NSMutableArray *panesOrder;

    NSString *bundleExtension;
    NSString *searchPath;
    
    NSToolbar *prefsToolbar;
    NSMutableDictionary *prefsToolbarItems;

    NSToolbarDisplayMode toolbarDisplayMode;
    NSToolbarSizeMode toolbarSizeMode;
    BOOL usesTexturedWindow;
    BOOL alwaysShowsToolbar;
    BOOL alwaysOpensCentered;
    
    BOOL debug;
	
	float minimumWidthForToolbar;
	
	id delegate;
}

// Convenience constructors
+ (id)preferencesWithPanesSearchPath:(NSString*)path bundleExtension:(NSString *)ext;
+ (id)preferencesWithBundleExtension:(NSString *)ext;
+ (id)preferencesWithPanesSearchPath:(NSString*)path;
+ (id)preferencesWithPanes:(NSArray *)inArray delegate:(id)inDelegate;
+ (id)preferences;

// Designated initializer
- (id)initWithPanesSearchPath:(NSString*)path bundleExtension:(NSString *)ext;

- (id)initWithBundleExtension:(NSString *)ext;
- (id)initWithPanesSearchPath:(NSString*)path;

- (void)showPreferencesWindow;
- (void)createPreferencesWindowAndDisplay:(BOOL)shouldDisplay;
- (void)createPreferencesWindow;
- (void)destroyPreferencesWindow;
- (BOOL)loadPrefsWithIdentifier:(NSString *)name display:(BOOL)disp;
- (BOOL)loadPreferencePaneNamed:(NSString *)name;
- (void)activatePane:(NSString*)path;
- (void)debugLog:(NSString*)msg;

float ToolbarHeightForWindow(NSWindow *window);
- (void)createPrefsToolbar;
- (void)prefsToolbarItemClicked:(NSToolbarItem*)item;

// Accessors
- (NSWindow *)preferencesWindow;
- (NSString *)bundleExtension;
- (NSString *)searchPath;

- (NSArray *)loadedPanes;
- (NSArray *)panesOrder;
- (void)setPanesOrder:(NSArray *)newPanesOrder;
- (BOOL)debug;
- (void)setDebug:(BOOL)newDebug;
- (BOOL)usesTexturedWindow;
- (void)setUsesTexturedWindow:(BOOL)newUsesTexturedWindow;
- (BOOL)alwaysShowsToolbar;
- (void)setAlwaysShowsToolbar:(BOOL)newAlwaysShowsToolbar;
- (BOOL)alwaysOpensCentered;
- (void)setAlwaysOpensCentered:(BOOL)newAlwaysOpensCentered;
- (NSToolbarDisplayMode)toolbarDisplayMode;
- (void)setToolbarDisplayMode:(NSToolbarDisplayMode)displayMode;
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_2
- (NSToolbarSizeMode)toolbarSizeMode;
- (void)setToolbarSizeMode:(NSToolbarSizeMode)sizeMode;
#endif

@end

@interface NSObject (SS_PrefsControllerDelegate)
- (void)prefsWindowWillClose:(SS_PrefsController *)sender;
@end
