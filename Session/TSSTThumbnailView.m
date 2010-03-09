//
//  TSSTThumbnailView.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 8/22/07.
//  Copyright 2007 Dancing Tortoise Software. All rights reserved.
//

#import "TSSTThumbnailView.h"
#import <QuartzCore/QuartzCore.h>
#import "TSSTSessionWindowController.h"
#import "TSSTImageUtilities.h"
#import "DTThumbnailController.h"

@implementation TSSTThumbnailView

- (void)scrollWheel:(NSEvent *)theEvent
{
	float change = [theEvent deltaY];
	CGRect bounds = [self layer].bounds;
	NSArray * layers = [[self layer] sublayers];
	CALayer * lastLayer = [layers lastObject];
	CALayer * firstLayer = [layers objectAtIndex: 0];
	float upperBound = CGRectGetMaxY([firstLayer frame]) - bounds.size.height + 20;
	float lowerBound = [lastLayer frame].origin.y - 20;
	
	float scrollPoint = bounds.origin.y + change * 10;
//	NSLog(@"%f %f %f", upperBound, lowerBound, scrollPoint);
	scrollPoint = scrollPoint > upperBound ? upperBound : scrollPoint;
	scrollPoint = scrollPoint < lowerBound ? lowerBound : scrollPoint;

	[(CAScrollLayer *)[self layer] scrollToPoint: CGPointMake(0, scrollPoint)];
	
}
//
//- (void)setFrame:(NSRect)frameRect
//{
//	CGPoint scrollPoint = [(CAScrollLayer *)[self layer] bounds].origin;
//	[super setFrame: frameRect];
//	[(CAScrollLayer *)[self layer] scrollToPoint: scrollPoint];
//}

@end


