//
//  TSSTSegmentedControl.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 6/14/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "TSSTSegmentedControl.h"
#import "TSSTSegmentedCell.h"
#import "TSSTImageUtilities.h"

@implementation TSSTSegmentedControl


/* This is just to compensate for transparency in newer versions
 of rounded textured buttons. */
- (void)drawRect:(NSRect)rect
{
    [NSGraphicsContext saveGraphicsState];
        NSRect actualDimensions = NSMakeRect(NSMinX(rect),
                                             NSMinY(rect) + 3,
                                             NSWidth(rect),
                                             NSHeight(rect) - 5);
        NSBezierPath * controlOutline = roundedRectWithCornerRadius( actualDimensions, 4);
        [controlOutline setClip];
        [[NSColor grayColor] set];
        NSRectFill(rect);
	[NSGraphicsContext restoreGraphicsState];

    [super drawRect: rect];
}


@end
