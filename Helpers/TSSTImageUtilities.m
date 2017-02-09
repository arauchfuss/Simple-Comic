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



#import "TSSTImageUtilities.h"


NSSize sizeConstrainedByDimension(NSSize size, float dimension)
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

NSSize scaleSize(NSSize aSize, float scale)
{
    if(NSEqualSizes(aSize , NSZeroSize))
    {
        return NSZeroSize;
    }
    
	NSSize outputSize;
	outputSize.width = (aSize.width * scale);
	outputSize.height = (aSize.height * scale);
	return outputSize;
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
    float x = rect.origin.x + ((rect.size.width - size.width) / 2);
    float y = rect.origin.y + ((rect.size.height - size.height) / 2);
    
    return NSMakeRect(x, y, size.width, size.height);
}

NSRect rectFromNegativeRect(NSRect rect)
{
	CGFloat possibleXOrigin = rect.origin.x + rect.size.width;
	CGFloat possibleYOrigin = rect.origin.y + rect.size.height;
	
	return NSMakeRect(possibleXOrigin < rect.origin.x ? possibleXOrigin : rect.origin.x,
					  possibleYOrigin < rect.origin.y ? possibleYOrigin : rect.origin.y,
					  fabs(rect.size.width), fabs(rect.size.height));
}

NSImage * imageScaledToSizeFromImage(NSSize size, NSImage * image)
{
	NSRect scaledRect = rectWithSizeCenteredInRect([image size] , NSMakeRect(0, 0, size.width, size.height));
	
	NSImage * scaledImage = [[NSImage alloc] initWithSize: size];
	
	[scaledImage lockFocus];
    [[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
	[scaledImage drawInRect: scaledRect fromRect: NSZeroRect operation: NSCompositeSourceOver fraction: 1.0];
    [scaledImage unlockFocus];
	
	return [scaledImage autorelease];
}



NSPoint centerPointOfRect(NSRect rect)
{
    NSPoint point;
    point.x = NSMinX(rect) + NSWidth(rect) / 2;
    point.y = NSMinY(rect) + NSHeight(rect) / 2;
    return point;
}


NSBezierPath * roundedRectWithCornerRadius(NSRect aRect, float radius)
{
    NSBezierPath * path = [NSBezierPath bezierPath];
    radius = MIN(radius, 0.5f * MIN(NSWidth(aRect), NSHeight(aRect)));
    NSRect rect = NSInsetRect(aRect, radius, radius);
    
    [path appendBezierPathWithArcWithCenter: NSMakePoint( NSMinX(rect), NSMinY(rect)) radius: radius startAngle: 180.0 endAngle: 270.0];
    [path appendBezierPathWithArcWithCenter: NSMakePoint( NSMaxX(rect), NSMinY(rect)) radius: radius startAngle: 270.0 endAngle: 360.0];
    [path appendBezierPathWithArcWithCenter: NSMakePoint( NSMaxX(rect), NSMaxY(rect)) radius: radius startAngle:  0.0 endAngle: 90.0];
    [path appendBezierPathWithArcWithCenter: NSMakePoint( NSMinX(rect), NSMaxY(rect)) radius: radius startAngle: 90.0 endAngle: 180.0];

    [path closePath];
    return path;	
}


CGImageRef CGImageRefNamed(NSString * name)
{
	NSData * imageData = [[NSImage imageNamed: name] TIFFRepresentation];
	
	CGImageRef        imageRef = NULL;
    CGImageSourceRef  sourceRef;
	
    sourceRef = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
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



