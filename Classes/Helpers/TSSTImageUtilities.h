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

	TSSTImageUtilities.h
*/

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const SCQuickLookCoverName;
extern NSString *const SCQuickLookCoverRect;

NSSize sizeConstrainedByDimension(NSSize size, CGFloat dimension) NS_SWIFT_NAME(constrainSize(_:dimension:));

/// function that adjusts an \c NSSize by the amount designated
/// in argument \c scale
/// Return is an integer size.
NSSize scaleSize(NSSize aSize, CGFloat scale) NS_SWIFT_NAME(scaleSize(_:scale:));
CGSize fitSizeInSize(CGSize constraint, CGSize size) NS_SWIFT_NAME(fitSize(_:in:));

NSRect rectWithSizeCenteredInRect(NSSize size, NSRect rect) NS_SWIFT_NAME(rectCentered(with:in:));

NSRect rectFromNegativeRect(NSRect rect);

NSImage * imageScaledToSizeFromImage(NSSize size, NSImage * image) NS_SWIFT_NAME(scaleImage(to:from:));

NSPoint centerPointOfRect(NSRect rect) NS_SWIFT_NAME(centerPoint(of:));

NSBezierPath * roundedRectWithCornerRadius(NSRect aRect, CGFloat radius) NS_SWIFT_NAME(roundedRect(_:cornerRadius:));

CGFloat RadiansToDegrees(CGFloat radians);

CGFloat DegreesToRadians(CGFloat degrees);

NS_ASSUME_NONNULL_END
