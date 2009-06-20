//
//  KeyboardPrefController.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 1/25/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "KeyboardPrefController.h"

#import "TSSTShortcutController.h"


static unsigned stripUnwantedModifiers(unsigned modifiers)
{
	unsigned cleanFlags = 0;
	cleanFlags = cleanFlags | modifiers & NSCommandKeyMask;
	cleanFlags = cleanFlags | modifiers & NSAlternateKeyMask;
	cleanFlags = cleanFlags | modifiers & NSShiftKeyMask;
	cleanFlags = cleanFlags | modifiers & NSControlKeyMask;
	
	return cleanFlags;
}


@implementation KeyboardPrefController


@synthesize allowEdit;
@synthesize shortcutList;
@synthesize shortcutSort;

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		shortcutList = [[TSSTShortcutController availableActions] retain];
		NSSortDescriptor * descriptionSort = [[NSSortDescriptor alloc] initWithKey: TSSTActionDescription ascending: YES];
		shortcutSort = [[NSArray alloc] initWithObjects: descriptionSort, nil];
		[descriptionSort release];
	}
	return self;
}


- (void)awakeFromNib
{
	self.allowEdit = NO;
	[shortcutTable setTarget: self];
	[shortcutTable setDoubleAction: @selector(editShortcut:)];
}


- (void) dealloc
{
	[shortcutSort release];
	[shortcutList release];
	[super dealloc];
}


- (void)setAllowEdit:(BOOL)allow
{
	allowEdit = allow;
	if(allow)
	{
		[messageField setStringValue: @"Type new shortcut now"];
	}
	else
	{
		[messageField setStringValue: @"Double click a row to edit its shortcut"];
	}
}



- (IBAction)editShortcut:(id)sender
{
	editRow = [shortcutController selectionIndex];
	self.allowEdit = YES;
	[[shortcutTable window] makeFirstResponder: shortcutTable];
}


/*	Okay this is complicated as all get out by my standards.  In fact if I can figure out a better
	solution it will get the axe.  Basic premiss is that there are two tables of values that hold the shortcut 
	preferences.  One the userdefaults controller which holds the key mapping and the other in this class
	which contains all of the descriptive crap about the key command.  They reference each other via a common
	set of keys.  Whenever a change is attempted to the key mapping the need key equivalent must be tested against 
	all of the existing key equivs.  So this command iterates through the whole local descripting array 
	of key commands grabbing key shortcuts from user prefs and testing them. */
- (void)assignKey:(NSString *)key withModifiers:(unsigned int)modifiers
{
	NSUserDefaultsController * defaults = [NSUserDefaultsController sharedUserDefaultsController];
	NSDictionary * values = [defaults values];
	NSDictionary * keyDefaults;
	BOOL safe = YES;
	unsigned testModifier;
	NSString * testKey;
	NSString * preferenceKey;
	modifiers = stripUnwantedModifiers(modifiers);
	NSDictionary * actionDescription;
//	NSLog(@"new: %u %@", modifiers, key);
	NSArray * forbidden = [TSSTShortcutController forbiddenShortcuts];
	
	for(actionDescription in forbidden)
	{
		testKey = [actionDescription objectForKey: @"menuKeyEquivalent"];
		testModifier = [[actionDescription objectForKey: @"menuModifierKey"] unsignedIntValue];
		
		if([testKey isEqualToString: key] && 
		   testModifier == modifiers)
		{
			safe = NO;
		}
	}
	
	for(actionDescription in shortcutList)
	{
		preferenceKey = [actionDescription valueForKey: @"preferenceKey"];
		keyDefaults = [values valueForKey: preferenceKey];
		
		testKey = [keyDefaults objectForKey: @"menuKeyEquivalent"];
		testModifier = [[keyDefaults objectForKey: @"menuModifierKey"] unsignedIntValue];
		
		if([testKey isEqualToString: key] && 
		   testModifier == modifiers)
		{
			safe = NO;
		}
	}
	
	if(safe)
	{
		NSString * selectedKey = [shortcutController valueForKeyPath: @"selection.preferenceKey"];
		
		NSDictionary * newKeys = [NSDictionary dictionaryWithObjectsAndKeys: key, @"menuKeyEquivalent",
								  [NSNumber numberWithUnsignedInt: modifiers], @"menuModifierKey", nil];

		[[defaults values] setValue: newKeys forKey: selectedKey];
	}
}



#pragma mark -
#pragma mark Preference Pane info



+ (NSArray *)preferencePanes
{
    return [NSArray arrayWithObjects: [[[KeyboardPrefController alloc] init] autorelease], nil];
}


- (NSView *)paneView
{
    BOOL loaded = YES;
    
    if (!prefsView) {
        loaded = [NSBundle loadNibNamed: @"KeyboardPrefPaneView" owner: self];
    }
    
    if (loaded) {
        return prefsView;
    }
    
    return nil;
}


- (NSString *)paneIdentifier
{
    return @"Shortcuts";
}


- (NSString *)paneName
{
    return NSLocalizedString(@"Shortcuts", @"Shortcuts Preferences Tab");
}


- (NSImage *)paneIcon
{
    return [NSImage imageNamed: @"Keyboard"];
}


- (NSString *)paneToolTip
{
    return NSLocalizedString(@"Keybaord Shortcuts Preferences", @"Tooltip for Keybaord Shortcuts Preferences");
}


- (BOOL)allowsHorizontalResizing
{
    return NO;
}


- (BOOL)allowsVerticalResizing
{
    return NO;
}

@end
