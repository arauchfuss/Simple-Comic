//
//  CenteredTextLayer.m
//  Simple Comic
//
//  Created by Franco Solerio on 17/04/2020.
//  Copyright © 2020 Dancing Tortoise Software. All rights reserved.
//

#import "CenteredTextLayer.h"

@implementation CenteredTextLayer

- (void)drawInContext:(CGContextRef)ctx {
	CGFloat height = self.bounds.size.height;
	CGFloat fontSize = self.fontSize;
	CGFloat yDiff = (height-fontSize)/2 - fontSize/10;
	
	CGContextSaveGState(ctx);
	CGContextTranslateCTM(ctx, 0, -yDiff);
	[super drawInContext:ctx];
	CGContextRestoreGState(ctx);
}

@end
