//
//  TSSTShortcutController.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 1/25/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TSSTShortcutController.h"

NSString * TSSTKeyboardEquivalents	= @"keyboardEquivalents";

NSString * TSSTMenuTag				= @"menuTag";
NSString * TSSTMenuAction			= @"menuAction";
NSString * TSSTMenuKeyEquivalent	= @"menuKeyEquivalent";
NSString * TSSTMenuModifierKey		= @"menuModifierKey";
NSString * TSSTActionDescription	= @"actionDescription";
NSString * TSSTPreferenceKey		= @"preferenceKey";


NSString * TSSTFullscreenShortcut		= @"fullscreenShortcut";
NSString * TSSTRotateRightShortcut		= @"rotateRightShortcut";
NSString * TSSTRotateLeftShortcut		= @"rotateLeftShortcut";
NSString * TSSTToggleLoupeShortcut		= @"toggleLoupeShortcut";
NSString * TSSTPageOrderShortcut		= @"pageOrderShortcut";
NSString * TSSTTwoPageShortcut			= @"twoPageShortcut";
NSString * TSSTOriginalSizeShortcut		= @"originalSizeShortcut";
NSString * TSSTHorizontalFitShortcut	= @"horizontalFitShortcut";
NSString * TSSTWindowFitShortcut		= @"windowFitShortcut";
NSString * TSSTThumbnailShortcut		= @"thumbnailShortcut";
NSString * TSSTZoomInShortcut			= @"zoomInShortcut";
NSString * TSSTZoomOutShortcut			= @"zoomOutShortcut";
NSString * TSSTPageRightShortcut		= @"pageRightShortcut";
NSString * TSSTPageLeftShortcut			= @"pageLeftShortcut";
NSString * TSSTFirstPageShortcut		= @"firstPageShortcut";
NSString * TSSTLastPageShortcut			= @"lastPageShortcut";
NSString * TSSTSkipRightShortcut		= @"skipRightShortcut";
NSString * TSSTSkipLeftShortcut			= @"skipLeftShortcut";
NSString * TSSTShiftRightShortcut		= @"shiftRightShortcut";
NSString * TSSTShiftLeftShortcut		= @"shiftLeftShortcut";
NSString * TSSTPageJumpShortcut			= @"pageJumpShortcut";



static NSMutableArray * forbiddenShortcuts = nil;

@implementation TSSTShortcutController



+ (void)initialize
{
	forbiddenShortcuts = [NSMutableArray new];
	
	NSDictionary * singleShortcut;
	singleShortcut = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
					  [NSString stringWithFormat: @"%C", NSLeftArrowFunctionKey], TSSTMenuKeyEquivalent, nil];
	[forbiddenShortcuts addObject: singleShortcut];
	[singleShortcut release];
	
	singleShortcut = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
					  [NSString stringWithFormat: @"%C", NSRightArrowFunctionKey], TSSTMenuKeyEquivalent, nil];
	[forbiddenShortcuts addObject: singleShortcut];
	[singleShortcut release];
	
	singleShortcut = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
					  [NSString stringWithFormat: @"%C", NSDownArrowFunctionKey], TSSTMenuKeyEquivalent, nil];
	[forbiddenShortcuts addObject: singleShortcut];
	[singleShortcut release];
	
	singleShortcut = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
					  [NSString stringWithFormat: @"%C", NSUpArrowFunctionKey], TSSTMenuKeyEquivalent, nil];
	[forbiddenShortcuts addObject: singleShortcut];
	[singleShortcut release];

	singleShortcut = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
					  @"b", TSSTMenuKeyEquivalent,
					  [NSNumber numberWithUnsignedInt: NSCommandKeyMask], TSSTMenuModifierKey, nil];
	[forbiddenShortcuts addObject: singleShortcut];
	[singleShortcut release];
	
	singleShortcut = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
					  @"B", TSSTMenuKeyEquivalent,
					  [NSNumber numberWithUnsignedInt: NSCommandKeyMask], TSSTMenuModifierKey, nil];
	[forbiddenShortcuts addObject: singleShortcut];
	[singleShortcut release];
}


+ (void)scrapeMenuKeyEquivalentsForMenu:(NSMenu *)menu
{
	NSArray * menuItems = [menu itemArray];
	BOOL match;
	NSDictionary * itemDescription;
	NSMenu * subMenu;
	for(NSMenuItem * menuItem in menuItems)
	{
		itemDescription = nil;
		match = NO;
		subMenu = [menuItem submenu];
		if(subMenu)
		{
			[TSSTShortcutController scrapeMenuKeyEquivalentsForMenu: subMenu];
		}
		else
		{
			if([menuItem keyEquivalent] && [menuItem keyEquivalentModifierMask])
			{
				itemDescription = [NSDictionary dictionaryWithObjectsAndKeys: 
								   [menuItem keyEquivalent], TSSTMenuKeyEquivalent,
								   [NSNumber numberWithUnsignedInt: [menuItem keyEquivalentModifierMask]], TSSTMenuModifierKey, nil];
			}
			else if([menuItem keyEquivalent])
			{
				itemDescription = [NSDictionary dictionaryWithObjectsAndKeys: 
								   [menuItem keyEquivalent], TSSTMenuKeyEquivalent, nil];
			}
			
			if(itemDescription)
			{
				[forbiddenShortcuts addObject: itemDescription];
			}
		}
	}
}


+ (NSArray *)availableActions
{
	NSMutableArray * actions = [NSMutableArray new];
	NSDictionary * singleShortcut;
	singleShortcut = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
					  @"changePageOrder:", TSSTMenuAction,
					  @"Change page order", TSSTActionDescription,
					  @"d", TSSTMenuKeyEquivalent,
					  [NSNumber numberWithUnsignedInt: NSCommandKeyMask], TSSTMenuModifierKey,
					  @"pageOrderShortcut", TSSTPreferenceKey, nil];
	[actions addObject: singleShortcut];
	[singleShortcut release];
	
	singleShortcut = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
					  @"setArchiveIcon:", TSSTMenuAction,
					  @"Set selected page as icon", TSSTActionDescription, 
					  @"defaultIcon", TSSTPreferenceKey,
					  @"c", TSSTMenuKeyEquivalent,
					  [NSNumber numberWithUnsignedInt: NSCommandKeyMask], TSSTMenuModifierKey, nil];
	[actions addObject: singleShortcut];
	[singleShortcut release];
	
	singleShortcut = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
					  @"changeTwoPage:", TSSTMenuAction,
					  @"Toggle two page spread", TSSTActionDescription, 
					  @"twoPageShortcut", TSSTPreferenceKey,
					  @"p", TSSTMenuKeyEquivalent,
					  [NSNumber numberWithUnsignedInt: NSCommandKeyMask], TSSTMenuModifierKey, nil];
	[actions addObject: singleShortcut];
	[singleShortcut release];
	
	singleShortcut = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
					  @"changeFullscreen:", TSSTMenuAction,
					  @"Toggle fullscreen", TSSTActionDescription, 
					  @"fullscreenShortcut", TSSTPreferenceKey,
					  @"f", TSSTMenuKeyEquivalent,
					  [NSNumber numberWithUnsignedInt: NSCommandKeyMask], TSSTMenuModifierKey, nil];
	[actions addObject: singleShortcut];
	[singleShortcut release];
	
	singleShortcut = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
					  @"togglePageExpose:", TSSTMenuAction,
					  @"Thumbnail exposé", TSSTActionDescription, 
					  @"thumbnailShortcut", TSSTPreferenceKey,
					  @"t", TSSTMenuKeyEquivalent,
					  [NSNumber numberWithUnsignedInt: NSCommandKeyMask], TSSTMenuModifierKey, nil];
	[actions addObject: singleShortcut];
	[singleShortcut release];
	
	singleShortcut = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
					  @"toggleLoupe:", TSSTMenuAction,
					  @"Toggle loupe", TSSTActionDescription, 
					  @"toggleLoupeShortcut", TSSTPreferenceKey,
					  @"u", TSSTMenuKeyEquivalent,
					  [NSNumber numberWithUnsignedInt: NSCommandKeyMask], TSSTMenuModifierKey, nil];
	[actions addObject: singleShortcut];
	[singleShortcut release];
	
	singleShortcut = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
					  @"zoomIn:", TSSTMenuAction,
					  @"Zoom in", TSSTActionDescription, 
					  @"zoomInShortcut", TSSTPreferenceKey,
					  @"=", TSSTMenuKeyEquivalent,
					  [NSNumber numberWithUnsignedInt: NSCommandKeyMask], TSSTMenuModifierKey, nil];
	[actions addObject: singleShortcut];
	[singleShortcut release];
	
	singleShortcut = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
					  @"zoomOut:", TSSTMenuAction,
					  @"Zoom out", TSSTActionDescription, 
					  @"zoomOutShortcut", TSSTPreferenceKey,
					  @"-", TSSTMenuKeyEquivalent,
					  [NSNumber numberWithUnsignedInt: NSCommandKeyMask], TSSTMenuModifierKey, nil];
	[actions addObject: singleShortcut];
	[singleShortcut release];
	
	singleShortcut = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
					  @"zoomReset:", TSSTMenuAction,
					  @"Zoom reset", TSSTActionDescription, 
					  @"zoomResetShortcut", TSSTPreferenceKey,
					  @"0", TSSTMenuKeyEquivalent,
					  [NSNumber numberWithUnsignedInt: NSCommandKeyMask], TSSTMenuModifierKey, nil];
	[actions addObject: singleShortcut];
	[singleShortcut release];
	
	singleShortcut = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
					  @"rotateLeft:", TSSTMenuAction,
					  @"Rotate left", TSSTActionDescription, 
					  @"rotateLeftShortcut", TSSTPreferenceKey, 
					  @"l", TSSTMenuKeyEquivalent,
					  [NSNumber numberWithUnsignedInt: NSCommandKeyMask], TSSTMenuModifierKey, nil];
	[actions addObject: singleShortcut];
	[singleShortcut release];
	
	singleShortcut = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
					  @"rotateRight:", TSSTMenuAction,
					  @"Rotate right", TSSTActionDescription, 
					  @"rotateRightShortcut", TSSTPreferenceKey,
					  @"r", TSSTMenuKeyEquivalent,
					  [NSNumber numberWithUnsignedInt: NSCommandKeyMask], TSSTMenuModifierKey, nil];
	[actions addObject: singleShortcut];
	[singleShortcut release];
	
	singleShortcut = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
					  @"noRotation:", TSSTMenuAction,
					  @"No Rotation", TSSTActionDescription,
					  @"n", TSSTMenuKeyEquivalent,
					  [NSNumber numberWithUnsignedInt: NSCommandKeyMask], TSSTMenuModifierKey,
					  @"noRotationShortcut", TSSTPreferenceKey, nil];
	[actions addObject: singleShortcut];
	[singleShortcut release];
	
	singleShortcut = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
					  @"changeScaling:", TSSTMenuAction,
					  [NSNumber numberWithInt: 400], TSSTMenuTag,
					  @"Original size mode", TSSTActionDescription, 
					  @"originalSizeShortcut", TSSTPreferenceKey,
					  @"1", TSSTMenuKeyEquivalent,
					  [NSNumber numberWithUnsignedInt: NSCommandKeyMask], TSSTMenuModifierKey, nil];
	[actions addObject: singleShortcut];
	[singleShortcut release];
	
	singleShortcut = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
					  @"changeScaling:", TSSTMenuAction,
					  [NSNumber numberWithInt: 401], TSSTMenuTag,
					  @"Scale pages to fit window", TSSTActionDescription, 
					  @"windowFitShortcut", TSSTPreferenceKey,
					  @"2", TSSTMenuKeyEquivalent,
					  [NSNumber numberWithUnsignedInt: NSCommandKeyMask], TSSTMenuModifierKey, nil];
	[actions addObject: singleShortcut];
	[singleShortcut release];
	
	singleShortcut = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
					  @"changeScaling:", TSSTMenuAction,
					  [NSNumber numberWithInt: 402], TSSTMenuTag,
					  @"Scale pages to fit window width", TSSTActionDescription, 
					  @"horizontalFitShortcut", TSSTPreferenceKey,
					  @"3", TSSTMenuKeyEquivalent,
					  [NSNumber numberWithUnsignedInt: NSCommandKeyMask], TSSTMenuModifierKey, nil];
	[actions addObject: singleShortcut];
	[singleShortcut release];
	
	singleShortcut = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
					  @"pageRight:", TSSTMenuAction,
					  @"Page right", TSSTActionDescription, 
					  TSSTPageRightShortcut, TSSTPreferenceKey,
					  [NSString stringWithFormat: @"%C", NSRightArrowFunctionKey], TSSTMenuKeyEquivalent,
					  [NSNumber numberWithUnsignedInt: NSCommandKeyMask], TSSTMenuModifierKey, nil];
	[actions addObject: singleShortcut];
	[singleShortcut release];
	
	singleShortcut = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
					  @"pageLeft:", TSSTMenuAction,
					  @"Page left", TSSTActionDescription, 
					  TSSTPageLeftShortcut, TSSTPreferenceKey,
					  [NSString stringWithFormat: @"%C", NSLeftArrowFunctionKey], TSSTMenuKeyEquivalent,
					  [NSNumber numberWithUnsignedInt: NSCommandKeyMask], TSSTMenuModifierKey, nil];
	[actions addObject: singleShortcut];
	[singleShortcut release];
	
	singleShortcut = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
					  @"firstPage:", TSSTMenuAction,
					  @"Jump to first page", TSSTActionDescription, 
					  TSSTFirstPageShortcut, TSSTPreferenceKey,
					  [NSString stringWithFormat: @"%C", NSHomeFunctionKey], TSSTMenuKeyEquivalent, nil];
	[actions addObject: singleShortcut];
	[singleShortcut release];
	
	singleShortcut = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
					  @"lastPage:", TSSTMenuAction,
					  @"Jump to last page", TSSTActionDescription, 
					  TSSTLastPageShortcut, TSSTPreferenceKey,
					  [NSString stringWithFormat: @"%C", NSEndFunctionKey], TSSTMenuKeyEquivalent,  nil];
	[actions addObject: singleShortcut];
	[singleShortcut release];
	
	singleShortcut = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
					  @"shiftPageRight:", TSSTMenuAction,
					  @"Shift one page right", TSSTActionDescription, 
					  TSSTShiftRightShortcut, TSSTPreferenceKey,
					  [NSString stringWithFormat: @"%C", NSRightArrowFunctionKey], TSSTMenuKeyEquivalent,
					  [NSNumber numberWithUnsignedInt: NSAlternateKeyMask], TSSTMenuModifierKey, nil];
	[actions addObject: singleShortcut];
	[singleShortcut release];
	
	singleShortcut = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
					  @"shiftPageLeft:", TSSTMenuAction,
					  @"Shift one page left", TSSTActionDescription, 
					  TSSTShiftLeftShortcut, TSSTPreferenceKey,
					  [NSString stringWithFormat: @"%C", NSLeftArrowFunctionKey], TSSTMenuKeyEquivalent,
					  [NSNumber numberWithUnsignedInt: NSAlternateKeyMask], TSSTMenuModifierKey, nil];
	[actions addObject: singleShortcut];
	[singleShortcut release];
	
	singleShortcut = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
					  @"skipRight:", TSSTMenuAction,
					  @"Skip ten pages right", TSSTActionDescription, 
					  TSSTSkipRightShortcut, TSSTPreferenceKey,
					  [NSString stringWithFormat: @"%C", NSRightArrowFunctionKey], TSSTMenuKeyEquivalent,
					  [NSNumber numberWithUnsignedInt: NSCommandKeyMask | NSAlternateKeyMask], TSSTMenuModifierKey, nil];
	[actions addObject: singleShortcut];
	[singleShortcut release];
	
	singleShortcut = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
					  @"skipLeft:", TSSTMenuAction,
					  @"Skip ten pages left", TSSTActionDescription, 
					  TSSTSkipLeftShortcut, TSSTPreferenceKey,
					  [NSString stringWithFormat: @"%C", NSLeftArrowFunctionKey], TSSTMenuKeyEquivalent,
					  [NSNumber numberWithUnsignedInt: NSCommandKeyMask | NSAlternateKeyMask], TSSTMenuModifierKey, nil];
	[actions addObject: singleShortcut];
	[singleShortcut release];
	
	singleShortcut = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
					  @"launchJumpPanel:", TSSTMenuAction,
					  @"Jump to specific page", TSSTActionDescription, 
					  TSSTPageJumpShortcut, TSSTPreferenceKey,
					  [NSString stringWithFormat: @"%C", NSCarriageReturnCharacter], TSSTMenuKeyEquivalent, nil];
	[actions addObject: singleShortcut];
	[singleShortcut release];
	
	return [actions autorelease];
}



+ (NSArray *)forbiddenShortcuts
{
	return forbiddenShortcuts;
}



+ (NSMutableDictionary *)defaultShortcutMapping
{
	NSMutableDictionary * shortcutDefaults = [NSMutableDictionary new];
	NSMutableDictionary * singleShortcut;
	
	NSArray * actions = [TSSTShortcutController availableActions];
	for(NSDictionary * action in actions)
	{
		singleShortcut = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
						  [action objectForKey: TSSTMenuKeyEquivalent], TSSTMenuKeyEquivalent,
						  [action objectForKey: TSSTMenuModifierKey], TSSTMenuModifierKey, nil];
		[shortcutDefaults setObject: singleShortcut forKey: [action objectForKey: TSSTPreferenceKey]];
	}
	
	return [shortcutDefaults autorelease];
}



+ (void)applyEquivalentWithDescription:(NSDictionary *)description toMenu:(NSMenu *)menu
{
//	NSLog([description description]);
	
	NSArray * menuItems = [menu itemArray];
	BOOL match;
	NSString * selectorString;
	
	for(NSMenuItem * menuItem in menuItems)
	{
		match = NO;
		NSMenu * subMenu = [menuItem submenu];
		if(subMenu)
		{
			[[self class] applyEquivalentWithDescription: description toMenu: subMenu];
		}
		else
		{
			selectorString = NSStringFromSelector([menuItem action]);
			if([[description valueForKey: TSSTMenuAction] isEqualToString: selectorString])
			{
				match = YES;
			}
			
			if([description valueForKey: TSSTMenuTag] && match)
			{
				match = [[description valueForKey: TSSTMenuTag] intValue] == [menuItem tag] ? YES : NO;
			}
			
			if(match)
			{
				[menuItem setKeyEquivalent: [description valueForKey: TSSTMenuKeyEquivalent]];
				[menuItem setKeyEquivalentModifierMask: [[description valueForKey: TSSTMenuModifierKey] unsignedIntValue]];
			}
		}
	}
}



- (void) dealloc
{
	NSUserDefaultsController * sharedDefaults = [NSUserDefaultsController sharedUserDefaultsController];
	
	NSArray * actions = [[self class] availableActions];
	for(NSMutableDictionary * action in actions)
	{
		[[sharedDefaults defaults] removeObserver: self forKeyPath: [action objectForKey: TSSTPreferenceKey]];
	}
	
	[super dealloc];
}



- (void)awakeFromNib
{
	NSMenu * applicationMenu = [[NSApplication sharedApplication] mainMenu];
	[[self class] scrapeMenuKeyEquivalentsForMenu: applicationMenu];
	
	NSUserDefaultsController * sharedDefaults = [NSUserDefaultsController sharedUserDefaultsController];
	NSDictionary * savedKey;
	NSArray * actions = [[self class] availableActions];
	for(NSMutableDictionary * action in actions)
	{
		savedKey = [[sharedDefaults values] valueForKey: [action objectForKey: TSSTPreferenceKey]];
		[action setValuesForKeysWithDictionary: savedKey];
		[[self class] applyEquivalentWithDescription: action toMenu: applicationMenu];
		
//		NSString * keyPath = [NSString stringWithFormat: @"values.%@", [action objectForKey: TSSTPreferenceKey]];
		[[sharedDefaults defaults] addObserver: self forKeyPath: [action objectForKey: TSSTPreferenceKey] options: 0 context: nil];
	}
}


- (void)observeValueForKeyPath:(NSString *)keyPath 
					  ofObject:(id)object 
						change:(NSDictionary *)change 
					   context:(void *)context
{
//	NSLog(keyPath);
	NSMenu * applicationMenu = [[NSApplication sharedApplication] mainMenu];
	NSUserDefaultsController * sharedDefaults = [NSUserDefaultsController sharedUserDefaultsController];
	NSArray * actions = [[self class] availableActions];
	NSArray * keys = [actions valueForKey: TSSTPreferenceKey];
	NSInteger index = [keys indexOfObject: keyPath];
	
	if(index != NSNotFound)
	{
		NSMutableDictionary * shortcutDescription = [NSMutableDictionary dictionaryWithDictionary: [actions objectAtIndex: index]];
		[shortcutDescription setValuesForKeysWithDictionary: [[sharedDefaults values] valueForKey: keyPath]];
//		NSLog([shortcutDescription description]);
		[[self class] applyEquivalentWithDescription: shortcutDescription toMenu: applicationMenu];
	}
}


@end

