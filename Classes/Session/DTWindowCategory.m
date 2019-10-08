//
//  DTWindowCategory.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 7/19/09.
//  Copyright 2009 Dancing Tortoise Software. All rights reserved.
//

#import "DTWindowCategory.h"
#import "TSSTSessionWindowController.h"
#import "SimpleComicAppDelegate.h"

@implementation NSWindow (DTWindowExtension)

- (CGFloat)toolbarHeight
{
    return NSHeight([self frame]) - NSHeight([[self contentView] frame]);
}


- (BOOL)isFullscreen
{
	return (([self styleMask] & NSWindowStyleMaskFullScreen) == NSWindowStyleMaskFullScreen);
}


@end
