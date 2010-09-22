//
//  TSSTPagePreview.h
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 6/7/08.
//  Copyright 2008 Dancing Tortoise Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TSSTPagePreview : NSObject
{
	IBOutlet NSView * preview;
	CALayer * firstPage;
	CALayer * secondPage;
	CALayer * arrowLayer;
	
	NSColor * pageBackground;
}

@property (nonatomic, retain) NSColor * pageBackground;

- (void)layoutPages;

@end


@interface TSSTPageOrderPreview : NSView
{
	
}


@end
