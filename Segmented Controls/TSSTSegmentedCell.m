//
//  TSSTSegmentedCell.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 6/14/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "TSSTSegmentedCell.h"
//#import "TSSTSegmentedControl.h"
#import "TSSTImageUtilities.h"


@implementation TSSTSegmentedCell

//
//- (void)drawSegment:(NSInteger)segment inFrame:(NSRect)frame withView:(NSSegmentedControl *)controlView
//{
//	if([controlView selectedSegment] != segment)
//	{
//		[super drawSegment: segment inFrame: frame withView: controlView];
//		return;
//	}
//	/* If the segment is selected an alternate image is grabbed. */
//    NSImage * icon = [self imageForSegment: segment];
//    
//    if(icon)
//    {
//		NSGradient * fillGradient;
//		NSRect IconRect = NSMakeRect(0, 0, [icon size].width, [icon size].height);
//        NSRect imageRect = rectWithSizeCenteredInRect([icon size], frame);
//		
//		NSImage * inverted = [[NSImage alloc] initWithSize: [icon size]];
//		
//		fillGradient = [[NSGradient alloc] initWithColorsAndLocations: [NSColor colorWithCalibratedRed:0 green:0.667 blue:0.871 alpha: 1.000], 0.0,
//						[NSColor colorWithCalibratedRed:0 green:0.773 blue:0.98 alpha: 1.000], 1.0, nil];
//		
//		[inverted lockFocus];
//
//		[fillGradient drawInRect: IconRect angle: 270];
//		
//		[icon drawInRect: IconRect fromRect: IconRect
//			   operation: NSCompositeDestinationIn fraction: 1];
//		
//		[inverted unlockFocus];
//
//		[inverted drawInRect: imageRect fromRect: IconRect 
//				   operation: NSCompositeSourceOver fraction: 1];
//		[inverted release];
//		[fillGradient release];
//
//    }
//}


@end

