//
//  TSSTPagePreview.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 6/7/08.
//  Copyright 2008 Dancing Tortoise Software. All rights reserved.
//

#import "TSSTPagePreview.h"
#import "SimpleComicAppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "TSSTImageUtilities.h"

@implementation TSSTPagePreview

@synthesize pageBackground;

- (void)awakeFromNib
{

	CALayer * root = [CALayer layer];
	CGRect previewFrame = NSRectToCGRect( preview.frame );
	previewFrame.origin = CGPointZero;
	preview.wantsLayer = YES;
	preview.layer = root;
    root.name = @"rootLayer";
    root.frame = previewFrame;
    root.delegate = self;
	root.layoutManager = [CAConstraintLayoutManager layoutManager];
	
	[self bind: @"pageBackground" 
	  toObject: [NSUserDefaults standardUserDefaults] 
   withKeyPath: TSSTBackgroundColor 
	   options: [NSDictionary dictionaryWithObject: NSUnarchiveFromDataTransformerName forKey: NSValueTransformerNameBindingOption]];
	
	[[NSUserDefaults standardUserDefaults] addObserver: self forKeyPath: TSSTTwoPageSpread options: 0 context: 0];
	[[NSUserDefaults standardUserDefaults] addObserver: self forKeyPath: TSSTPageOrder options: 0 context: 0];

	firstPage = [CALayer new];
	[firstPage setDelegate: self];
	secondPage = [CALayer new];
	[secondPage setDelegate: self];
	
	arrowLayer = [CALayer new];
	[arrowLayer setDelegate: self];

	CGImageRef image = CGImageRefNamed(@"arrow");
	arrowLayer.contents = (id)image;
	arrowLayer.bounds = CGRectMake(0, 0, 63, 36);
	arrowLayer.shadowOpacity = 0.6;
	CGImageRelease(image);
	[[preview layer] addSublayer: arrowLayer];
	[arrowLayer addConstraint:[CAConstraint constraintWithAttribute: kCAConstraintMidY
														 relativeTo: @"superlayer"
														  attribute: kCAConstraintMidY]];
	[arrowLayer addConstraint:[CAConstraint constraintWithAttribute: kCAConstraintMidX
														 relativeTo: @"superlayer"
														  attribute: kCAConstraintMidX]];
	arrowLayer.zPosition = 3;
	[arrowLayer release];
	
	image = CGImageRefNamed(@"preview_1");

	firstPage.shadowOpacity = 0.8;
	firstPage.contents = (id)image;
	CGImageRelease(image);
	firstPage.zPosition = 1;
	
	image = CGImageRefNamed(@"preview_2");
//	secondPage.backgroundColor = colorRef;
	secondPage.shadowOpacity = 0.8;
	secondPage.contents = (id)image;
	CGImageRelease(image);
//	CGColorRelease(colorRef);
	secondPage.zPosition = 2;
	
	[[preview layer] addSublayer: firstPage];
	[self layoutPages];
}


- (void) dealloc
{
	[[NSUserDefaults standardUserDefaults] removeObserver: self forKeyPath: TSSTPageOrder];
	[[NSUserDefaults standardUserDefaults] removeObserver: self forKeyPath: TSSTTwoPageSpread];
	[self unbind: @"pageBackground"];
	
	[pageBackground release];
	[firstPage release];
	[secondPage release];
	[arrowLayer release];
	
	[super dealloc];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	[self layoutPages];
}


- (void)layoutPages
{
	CALayer * root = [preview layer];
	CGRect frame = root.frame;
	float height = CGRectGetHeight(frame);
	float width = height * 0.79;
	
	BOOL spread = [[[NSUserDefaults standardUserDefaults] valueForKey: TSSTTwoPageSpread] boolValue];
	BOOL order = [[[NSUserDefaults standardUserDefaults] valueForKey: TSSTPageOrder] boolValue];
	
	
	if(!order)
	{
		arrowLayer.shadowOffset = CGSizeMake(0, 3);
		arrowLayer.transform = CATransform3DRotate(CATransform3DIdentity, DegreesToRadians( 180 ), 0, 0, 1);
	}
	else
	{
		arrowLayer.shadowOffset = CGSizeMake(0, -3);
		arrowLayer.transform = CATransform3DIdentity;
	}

		
	if(!spread)
	{
		CGRect pageRect = CGRectMake( CGRectGetWidth(frame) / 2 - width / 2, 0, width, height);
		pageRect = CGRectInset(pageRect, 10, 10);
		[secondPage removeFromSuperlayer];
		firstPage.frame = pageRect;
	}
	else
	{
		[[preview layer] addSublayer: secondPage];
		CGRect leftRect = CGRectMake( CGRectGetWidth(frame) / 2 - width, 0, width, height);
		CGRect rightRect = CGRectMake( CGRectGetWidth(frame) / 2, 0, width, height);
		leftRect = CGRectInset(leftRect, 10, 10);
		rightRect = CGRectInset(rightRect, 10, 10);
//		leftRect.origin.x += 10;
//		rightRect.origin.x -= 10;
		if(order)
		{
			firstPage.frame = leftRect;
			secondPage.frame = rightRect;
		}
		else
		{
			firstPage.frame = rightRect;
			secondPage.frame = leftRect;
		}
	}
}



- (void)setPageBackground:(NSColor *)color
{
	[pageBackground release];
	pageBackground = [color retain];
	CGFloat red, green, blue, alpha;
	color = [color colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
	[color getRed: &red green: &green blue: &blue alpha: &alpha];
	CGColorRef colorRef = CGColorCreateGenericRGB(red, green, blue, alpha);
	[[preview layer] setBackgroundColor: colorRef];
	CGColorRelease( colorRef);
	[[preview layer] setNeedsDisplay];
}



#pragma mark -
#pragma mark CA Delegates


@end


@implementation TSSTPageOrderPreview


- (void)mouseUp:(NSEvent *)theEvent
{
	CALayer * arrow = [[[self layer] sublayers] objectAtIndex: 0];
	CGPoint clickLocation = NSPointToCGPoint([self convertPoint: [theEvent locationInWindow] fromView: nil]);
	
	if([arrow containsPoint:[arrow convertPoint:clickLocation fromLayer: [self layer]]])
	{
		BOOL order = [[[NSUserDefaults standardUserDefaults] valueForKey: @"pageOrder"] boolValue];
		[[NSUserDefaults standardUserDefaults] setValue: [NSNumber numberWithBool: !order] forKey: @"pageOrder"];
	}
}

@end

