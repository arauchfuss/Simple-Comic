//
//  DTSessionWindow.h
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 7/19/09.
//  Copyright 2009 Dancing Tortoise Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DTSessionWindow : NSWindow

@property (readonly) CGFloat toolbarHeight;
@property (getter=isFullscreen, readonly) BOOL fullscreen;

@end
