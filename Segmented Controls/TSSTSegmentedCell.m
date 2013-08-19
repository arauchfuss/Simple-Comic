//
//  TSSTSegmentedCell.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 6/14/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "TSSTSegmentedCell.h"
#import "TSSTSegmentedControl.h"
#import "TSSTImageUtilities.h"


@implementation TSSTSegmentedCell


- (void)drawSegment:(NSInteger)segment inFrame:(NSRect)frame withView:(NSSegmentedControl *)controlView
{
    [[NSColor whiteColor] set];
    NSRectFill(frame);
    [super drawSegment: segment inFrame: frame withView: controlView];
}


@end

