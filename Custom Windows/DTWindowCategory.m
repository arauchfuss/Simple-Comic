//
//  DTWindowCategory.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 7/19/09.
//  Copyright 2009 Dancing Tortoise Software. All rights reserved.
//

#import "DTWindowCategory.h"

@implementation NSWindow (DTWindowExtension)

- (float)toolbarHeight
{
    return NSHeight([self frame]) - NSHeight([[self contentView] frame]);
}


- (BOOL)isFullscreen
{
    return (([self styleMask] & NSFullScreenWindowMask) == NSFullScreenWindowMask);
}


@end
