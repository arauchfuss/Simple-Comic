//
//  DTImageView.m
//  Simple Comic 2
//
//  Created by Alexander Rauchfuss on 11/26/11.
//  Copyright (c) 2011 Dancing Tortoise Software. All rights reserved.
//

#import "DTImageView.h"

@implementation DTImageView

@synthesize page;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect bounds = [self bounds];

    if(!page)
    {
        [[NSColor whiteColor] set];
        NSRectFill(bounds);
    }
    
    [page drawInRect: bounds
            fromRect: NSZeroRect
           operation: NSCompositeSourceOver
            fraction: 1.0];
}

@end
