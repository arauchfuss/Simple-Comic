/*	
	Copyright (c) 2006-2009 Dancing Tortoise Software
 
	Permission is hereby granted, free of charge, to any person 
	obtaining a copy of this software and associated documentation
	files (the "Software"), to deal in the Software without 
	restriction, including without limitation the rights to use, 
	copy, modify, merge, publish, distribute, sublicense, and/or 
	sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following 
	conditions:
 
	The above copyright notice and this permission notice shall be
	included in all copies or substantial portions of the Software.
 
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
	OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
	OTHER DEALINGS IN THE SOFTWARE.
	
	Simple Comic
	TSSTImageUtilities.m
*/


#include <math.h>
#include <tgmath.h>

#import "TSSTImageUtilities.h"


NSSize sizeConstrainedByDimension(NSSize size, CGFloat dimension)
{
//	if(size.width > dimension || size.height > dimension)
//    {
        if( 1 > size.height / size.width)
        {
			size = scaleSize(size, dimension / size.width);
        }
        else
        {
			size = scaleSize(size, dimension / size.height);
        }
//    }
	
    return size;
}

NSSize scaleSize(NSSize aSize, CGFloat scale)
{
    if(NSEqualSizes(aSize , NSZeroSize))
    {
        return NSZeroSize;
    }
    
	NSSize outputSize = aSize;
	outputSize.width *= scale;
	outputSize.height *= scale;
	return outputSize;
}


CGSize fitSizeInSize(CGSize constraint, CGSize size)
{
	if(size.width < constraint.width || size.height < constraint.height)
	{
		if( constraint.height / constraint.width > size.width / size.width)
		{
			size = scaleSize(size, size.height / constraint.height);
		}
		else
		{
			size = scaleSize(size, size.width / constraint.width);
		}
	}
	
	return size;
}


NSRect rectWithSizeCenteredInRect(NSSize size, NSRect rect)
{
    if(NSWidth(rect) < size.width || NSHeight(rect) < size.height)
    {
        if( size.height / size.width > NSHeight(rect) / NSWidth(rect))
        {
            size = scaleSize(size, NSHeight(rect) / size.height);
        }
        else
        {
            size = scaleSize(size, NSWidth(rect) / size.width);
        }
    }
    CGFloat x = rect.origin.x + ((rect.size.width - size.width) / 2);
    CGFloat y = rect.origin.y + ((rect.size.height - size.height) / 2);
    
    return NSMakeRect(x, y, size.width, size.height);
}

NSRect rectFromNegativeRect(NSRect rect)
{
	return CGRectStandardize(rect);
}

NSImage * imageScaledToSizeFromImage(NSSize size, NSImage * image)
{
	NSRect scaledRect = rectWithSizeCenteredInRect([image size] , NSMakeRect(0, 0, size.width, size.height));
	
	NSImage * scaledImage = [[NSImage alloc] initWithSize: size];
	
	[scaledImage lockFocus];
    [[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
	[scaledImage drawInRect: scaledRect fromRect: NSZeroRect operation: NSCompositeSourceOver fraction: 1.0];
    [scaledImage unlockFocus];
	
	return scaledImage;
}



NSPoint centerPointOfRect(NSRect rect)
{
    NSPoint point;
    point.x = NSMidX(rect);
    point.y = NSMidY(rect);
    return point;
}


NSBezierPath * roundedRectWithCornerRadius(NSRect aRect, CGFloat radius)
{
	return [NSBezierPath bezierPathWithRoundedRect: aRect xRadius: radius yRadius: radius];
}


CGImageRef CGImageRefNamed(NSString * name)
{
	NSData * imageData = [[NSImage imageNamed: name] TIFFRepresentation];
	
	CGImageRef        imageRef = NULL;
    CGImageSourceRef  sourceRef;
	
    sourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
    if(sourceRef)
	{
        imageRef = CGImageSourceCreateImageAtIndex(sourceRef, 0, NULL);
        CFRelease(sourceRef);
    }
	
    return imageRef;
}


CGFloat DegreesToRadians(CGFloat degrees) 
{
	return degrees * M_PI / 180;
}

CGFloat RadiansToDegrees(CGFloat radians) 
{
	return radians * 180 / M_PI;
}



