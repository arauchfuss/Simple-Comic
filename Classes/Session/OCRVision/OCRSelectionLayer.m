//  OCRSelectionLayer.m
//
//  Created by David Phillip Oster on 5/26/2022 Apache Version 2 open source license.
//

#import "OCRSelectionLayer.h"

#import "OCRTracker.h"
#import <Vision/Vision.h>

static CGPathRef CGPathFromNSBezierQuadPath(NSBezierPath *path)
{
	CGMutablePathRef p = CGPathCreateMutable();
	NSInteger numElements = [path elementCount];
	NSPoint points[3];
	for (NSInteger i = 0; i < numElements; i++)
	{
		switch ([path elementAtIndex:i associatedPoints:points])
		{
			case NSMoveToBezierPathElement:
				CGPathMoveToPoint(p, NULL, points[0].x, points[0].y);
				break;
			case NSLineToBezierPathElement:
				CGPathAddLineToPoint(p, NULL, points[0].x, points[0].y);
				break;
			case NSBezierPathElementClosePath:
				CGPathCloseSubpath(p);
				break;
			default:
				break;
		}
	}
	return p;
}

@implementation OCRSelectionLayer

- (instancetype)initWithObservations:(NSArray *)observations selection:(NSDictionary *)selection  imageLayer:(CALayer *)imageLayer
{
	self = [super init];
	if (self) {
		[self setPosition:imageLayer.position];
		[self setBounds:imageLayer.bounds];
		NSAffineTransform *transform = [NSAffineTransform transform];
		[transform scaleXBy:self.bounds.size.width yBy:self.bounds.size.height];
		self.fillColor = [NSColor.controlAccentColor CGColor];
		self.opacity = 0.4;
		CGMutablePathRef pAll = CGPathCreateMutable();
		for (VNRecognizedTextObservation *piece in observations)
		{
			NSValue *rangeValue = selection[piece];
			if (rangeValue != nil)
			{
				NSBezierPath *path1 = OCRBezierPathFromTextObservationRange(piece, rangeValue.rangeValue);
				[path1 transformUsingAffineTransform:transform];
				CGPathRef p = CGPathFromNSBezierQuadPath(path1);
				CGPathAddPath(pAll, NULL, p);
				CGPathRelease(p);
			}
		}
		self.path = pAll;
		CGPathRelease(pAll);

		[self setNeedsDisplay];
	}
	return self;
}

@end

