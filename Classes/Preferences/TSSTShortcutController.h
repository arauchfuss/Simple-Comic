//
//  TSSTShortcutController.h
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 1/25/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * TSSTKeyboardEquivalents;

extern NSString * TSSTMenuTag;
extern NSString * TSSTMenuAction;
extern NSString * TSSTMenuKeyEquivalent;
extern NSString * TSSTMenuModifierKey;
extern NSString * TSSTActionDescription;

extern NSString * TSSTFullscreenShortcut;
extern NSString * TSSTRotateRightShortcut;
extern NSString * TSSTRotateLeftShortcut;
extern NSString * TSSTToggleLoupeShortcut;
extern NSString * TSSTPageOrderShortcut;
extern NSString * TSSTTwoPageShortcut;
extern NSString * TSSTOriginalSizeShortcut;
extern NSString * TSSTHorizontalFitShortcut;
extern NSString * TSSTWindowFitShortcut;
extern NSString * TSSTThumbnailShortcut;
extern NSString * TSSTZoomInShortcut;
extern NSString * TSSTZoomOutShortcut;
extern NSString * TSSTZoomResetShortcut;
extern NSString * TSSTPageRightShortcut;
extern NSString * TSSTPageLeftShortcut;
extern NSString * TSSTFirstPageShortcut;
extern NSString * TSSTLastPageShortcut;
extern NSString * TSSTSkipRightShortcut;
extern NSString * TSSTSkipLeftShortcut;
extern NSString * TSSTShiftRightShortcut;
extern NSString * TSSTShiftLeftShortcut;
extern NSString * TSSTPageJumpShortcut;

@interface TSSTShortcutController : NSObject
{

}

+ (NSArray *)availableActions;
+ (NSMutableDictionary *)defaultShortcutMapping;
+ (NSArray *)forbiddenShortcuts;
+ (void)scrapeMenuKeyEquivalentsForMenu:(NSMenu *)menu;

+ (void)applyEquivalentWithDescription:(NSDictionary *) description toMenu:(NSMenu *)menu;



@end
