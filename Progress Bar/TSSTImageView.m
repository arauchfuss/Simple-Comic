//
//  TSSTImageView.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 7/15/07.
//  Copyright 2007 Dancing Tortoise Software. All rights reserved.
//

#import "TSSTImageView.h"
#import "TSSTImageUtilities.h"

static NSDictionary * stringAttributes;

@implementation TSSTImageView


@synthesize imageName;


+ (void)initialize
{
    NSMutableParagraphStyle * style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [style setLineBreakMode: NSLineBreakByTruncatingHead];
    stringAttributes = [@{NSFontAttributeName: [NSFont fontWithName: @"Lucida Grande" size: 14],
                         NSForegroundColorAttributeName: [NSColor colorWithCalibratedWhite: 1 alpha: 1.0],
                         NSParagraphStyleAttributeName: style} retain];
    [style release];
}


- (id) init
{
    self = [super init];
    if (self != nil)
    {
        clears = NO;
    }
    return self;
}



- (void)setClears:(BOOL)canClear
{
    clears = canClear;
}


- (BOOL)clears
{
    return clears;
}



- (void)drawRect:(NSRect)rect
{
    if(clears)
    {
        [[NSColor clearColor] set];
        NSRectFill( [self bounds]);
    }
    
    NSRect imageRect = rectWithSizeCenteredInRect([[self image] size], [self bounds]);
//    [NSGraphicsContext saveGraphicsState];
//    [[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
    [[self image] drawInRect: imageRect
					fromRect: NSZeroRect 
				   operation: NSCompositeSourceOver 
					fraction: 1];
    if(self.imageName)
    {
        imageRect = NSInsetRect(imageRect,  10, 10);
        NSRect stringRect = [self.imageName boundingRectWithSize: imageRect.size options: 0 attributes: stringAttributes];
        stringRect = rectWithSizeCenteredInRect(stringRect.size, imageRect);
        [[NSColor colorWithCalibratedWhite: 0 alpha: 0.8] set];
        [roundedRectWithCornerRadius(NSInsetRect(stringRect, -5, -5), 10) fill];
        [self.imageName drawInRect: stringRect withAttributes: stringAttributes];
    }
    
//    [NSGraphicsContext restoreGraphicsState];
}


@end
