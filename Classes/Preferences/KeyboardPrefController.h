//
//  KeyboardPrefController.h
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 1/25/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SS_PreferencePaneProtocol.h"

@interface KeyboardPrefController : NSObject <SS_PreferencePaneProtocol> {
	
    IBOutlet NSView * prefsView;
	
	IBOutlet NSTableView		* shortcutTable;
	IBOutlet NSArrayController	* shortcutController;
	
	IBOutlet NSTextField		* messageField;
	
	NSArray * shortcutList;
	NSArray * shortcutSort;
	BOOL allowEdit;
	int editRow;

}

@property (readonly) NSArray * shortcutSort;
@property (readonly) NSArray * shortcutList;
@property (assign) BOOL allowEdit;

- (IBAction)editShortcut:(id)sender;
- (void)assignKey:(NSString *)key withModifiers:(unsigned int)modifiers;


@end
