//
//  DTSessionWindow.h
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 7/19/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DTSessionWindow : NSWindow
{
	BOOL fullscreen;
}

@property (assign) BOOL fullscreen;

- (float)toolbarHeight;

@end
