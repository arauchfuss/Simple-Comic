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
	SimpleComicAppDelegate.h
*/

#import <Cocoa/Cocoa.h>

#if (MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_12)
#define NSCompositingOperationSourceOver NSCompositeSourceOver
#define NSEventModifierFlagCommand       NSCommandKeyMask
#define NSEventModifierFlagOption        NSAlternateKeyMask
#define NSEventModifierFlagShift         NSShiftKeyMask
#define NSEventTypeKeyDown               NSKeyDown
#define NSEventTypeLeftMouseUp           NSLeftMouseUp
#define NSEventTypeLeftMouseDragged      NSLeftMouseDragged
#endif

NS_ASSUME_NONNULL_BEGIN

@class TSSTSessionWindowController;
@class TSSTManagedArchive;
@class TSSTManagedGroup;
@class TSSTManagedPDF;
@class TSSTManagedSession;
@class DTPreferencesController;

extern NSString *const TSSTPageOrder;
extern NSString *const TSSTPageScaleOptions;
extern NSString *const TSSTTwoPageSpread;
extern NSString *const TSSTStatusbarVisible;
extern NSString *const TSSTBackgroundColor;
extern NSString *const TSSTConstrainScale;
extern NSString *const TSSTWindowAutoResize;
extern NSString *const TSSTSessionRestore;
extern NSString *const TSSTEnableSwipe;
extern NSString *const TSSTLoupeDiameter;
extern NSString *const TSSTLoupePower;
extern NSString *const TSSTLonelyFirstPage;
extern NSString *const TSSTScrollersVisible;
extern NSString *const TSSTPreserveModDate;
extern NSString *const TSSTUnifiedTitlebar;
extern NSString *const TSSTFullscreenToolbar;

extern NSString *const TSSTScrollPosition;
extern NSString *const TSSTZoomLevel;
extern NSString *const TSSTViewRotation;
extern NSString *const TSSTSessionEndNotification;

/*!
    This class is the application delegate.
    It handles the following:

    The Core Data store
    File loading
    Session auto-save
    Archive password prompts during their loading
    Fallback archive encoding selection
*/
@interface SimpleComicAppDelegate : NSObject <NSApplicationDelegate>
/*! When opening encrypted zip or rar archives this panel is
 made visible as a modal so the user can enter a password. */
@property (weak) IBOutlet NSPanel           * passwordPanel;
@property (weak) IBOutlet NSSecureTextField * passwordField;

/*! This panel appears when the text encoding auto-detection fails */
@property (weak) IBOutlet NSPanel           * encodingPanel;
@property (weak) IBOutlet NSTextField       * encodingTestField;
@property (weak) IBOutlet NSPopUpButton     * encodingPopup;


/*! Bound to the encoding list drop down. */
@property (assign) NSInteger encodingSelection;

/*! Convenience method for adding metadata to the core data store.
    Used by Simple Comic to keep track of store versioning. */
+ (void)setMetadata:(NSString *)value forKey:(NSString *)key onStoreWithURL:(NSURL *)url managedBy:(NSPersistentStoreCoordinator *)coordinator;

/*! Core Data methods, slightly altered boilerplate. */
@property (readonly, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong) NSManagedObjectContext *managedObjectContext;
@property (readonly, copy) NSString *applicationSupportFolder;
- (BOOL) saveContext;


/*! Creates a new Session object based on user prefs and then
    passes the files array to addFiles:toSesion: */
- (TSSTManagedSession *)newSessionWithFiles:(NSArray<NSString*> *)files NS_RETURNS_NOT_RETAINED;

/*! This method is called every time an existing session needs
    to be made visible to a user. */
- (void)windowForSession:(TSSTManagedSession *)session;

/*! When an end session notification is received this method
	is called. */
- (void)endSession:(NSNotification *)notification;

/*! This method is called at launch, it iterates through all of the saved
    sessions calling windowForSession: for each in turn. */
- (void)sessionRelaunch;

/*! This method adds any file passed to it to a session.  This includes recursive
	parsing of archives and folders. */
- (void)addFiles:(NSArray<NSString*> *)paths toSession:(TSSTManagedSession *)session;

/*! Called when Simple Comic encounters a password protected
    archive.  Brings a password dialog forward. */
- (nullable NSString*)passwordForArchiveWithPath:(NSString*)filename;


- (void)generateEncodingMenu;
/*! Updates the encoding menu for an archive.
    Grays out all encodings that do not work with the
    argument string  */
- (void)updateEncodingMenuTestedAgainst:(NSData *)data;
/*! Modal that displays all available string encodings
    and allows the user to pick one. */
- (IBAction)testEncoding:(nullable id)sender;
- (IBAction)testEncodingMenu:(nullable id)sender;

/*! Launches the preferences window manager. */
- (IBAction)openPreferences:(nullable id)sender;

/*! Starts an NSOpenPanel with auxiliary view */
- (IBAction)addPages:(nullable id)sender;
/* These are called by modals that want to end */
/*! Kills the password and encoding modals if the OK button was clicked. */
- (IBAction)modalOK:(nullable id)sender;
/*! Kills the password and encoding modals if the Cancel button was clicked. */
- (IBAction)modalCancel:(nullable id)sender;

@end

NS_ASSUME_NONNULL_END
