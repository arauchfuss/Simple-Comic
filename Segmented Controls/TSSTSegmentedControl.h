//
//  TSSTSegmentedControl.h
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 6/14/07.
//  Copyright 2007 Dancing Tortoise Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TSSTSegmentedControl : NSSegmentedControl
{
    int mouseDownSegment;
}

+ (float)cornerRadius;

- (int)mouseDownSegment;
- (int)segmentAtPoint:(NSPoint) point;

@end
