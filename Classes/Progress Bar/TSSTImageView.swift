//
//  TSSTImageView.swift
//  SimpleComic
//
//  Created by C.W. Betts on 10/26/15.
//
//

import Cocoa

private let stringAttributes: [String: AnyObject] = {
	let style = NSParagraphStyle.default().mutableCopy() as! NSMutableParagraphStyle
	style.lineBreakMode = .byTruncatingHead
	return [NSFontAttributeName: NSFont.labelFont(ofSize: 14),
		NSForegroundColorAttributeName: NSColor(calibratedWhite: 1, alpha: 1),
		NSParagraphStyleAttributeName: style]
}()

class TSSTImageView : NSImageView {
	var imageName: String?
	var clears: Bool = false

	override func draw(_ dirtyRect: NSRect) {
		if clears {
			NSColor.clear.set()
			NSRectFill(bounds)
		}
		
		var imageRect = rectWithSizeCenteredInRect(image?.size ?? .zero, bounds)
		//[NSGraphicsContext saveGraphicsState];
		//[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
		image?.draw(in: imageRect, from: .zero, operation: .sourceOver, fraction: 1)
		if let imageName = imageName {
			imageRect = imageRect.insetBy(dx: 10, dy: 10)
			//imageRect.insetInPlace(dx: 10, dy: 10)
			var stringRect = imageName.boundingRect(with: imageRect.size, options: [], attributes: stringAttributes)
			stringRect = rectWithSizeCenteredInRect(stringRect.size, imageRect);
			NSColor(calibratedWhite: 0, alpha: 0.8).set()
			roundedRectWithCornerRadius(stringRect.insetBy(dx: -5, dy: -5), 10).fill()
			imageName.draw(in: stringRect, withAttributes: stringAttributes)
		}
		
		//[NSGraphicsContext restoreGraphicsState];
	}
}
