//
//  TSSTImageView.swift
//  SimpleComic
//
//  Created by C.W. Betts on 10/26/15.
//
//

import Cocoa

private let stringAttributes: [String: AnyObject] = {
	let style = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
	style.lineBreakMode = .ByTruncatingHead
	return [NSFontAttributeName: NSFont(name: "Lucida Grande", size: 14)!,
		NSForegroundColorAttributeName: NSColor(calibratedWhite: 1, alpha: 1),
		NSParagraphStyleAttributeName: style]
}()

class TSSTImageView : NSImageView {
	var imageName: String?
	var clears: Bool = false

	override func drawRect(dirtyRect: NSRect) {
		if clears {
			NSColor.clearColor().set()
			NSRectFill(bounds)
		}
		
		var imageRect = rectWithSizeCenteredInRect(image?.size ?? .zero, bounds)
		//[NSGraphicsContext saveGraphicsState];
		//[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
		image?.drawInRect(imageRect, fromRect: .zero, operation: .CompositeSourceOver, fraction: 1)
		if let imageName = imageName {
			imageRect.insetInPlace(dx: 10, dy: 10)
			var stringRect = imageName.boundingRectWithSize(imageRect.size, options: [], attributes: stringAttributes)
			stringRect = rectWithSizeCenteredInRect(stringRect.size, imageRect);
			NSColor(calibratedWhite: 0, alpha: 0.8).set()
			roundedRectWithCornerRadius(stringRect.insetBy(dx: -5, dy: -5), 10).fill()
			imageName.drawInRect(stringRect, withAttributes: stringAttributes)
		}
		
		//[NSGraphicsContext restoreGraphicsState];
	}
}
