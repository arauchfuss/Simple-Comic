//
//  TSSTImageView.swift
//  SimpleComic
//
//  Created by C.W. Betts on 10/26/15.
//
//

import Cocoa

private let stringAttributes: [NSAttributedString.Key: Any] = {
	let style = NSMutableParagraphStyle()
	style.lineBreakMode = .byTruncatingHead
	return [.font: NSFont.labelFont(ofSize: 14),
			.foregroundColor: NSColor.white,
			.paragraphStyle: style.copy()]
}()

class TSSTImageView: NSImageView {
	var imageName: String?
	var clears: Bool = false
	
	override func draw(_ dirtyRect: NSRect) {
		if clears {
			NSColor.clear.set()
			bounds.fill()
		}
		
		var imageRect = rectCentered(with: image?.size ?? .zero, in: bounds)
		//[NSGraphicsContext saveGraphicsState];
		//[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
		image?.draw(in: imageRect, from: .zero, operation: .sourceOver, fraction: 1)
		if let imageName = imageName {
			imageRect = imageRect.insetBy(dx: 10, dy: 10)
			var stringRect = imageName.boundingRect(with: imageRect.size, attributes: stringAttributes)
			stringRect = rectCentered(with: stringRect.size, in: imageRect);
			NSColor(calibratedWhite: 0, alpha: 0.8).set()
			NSBezierPath(roundedRect: stringRect.insetBy(dx: -5, dy: -5), cornerRadius: 10).fill()
			imageName.draw(in: stringRect, withAttributes: stringAttributes)
		}
		
		//[NSGraphicsContext restoreGraphicsState];
	}
}

extension NSBezierPath {
	@inlinable convenience init(roundedRect aRect: NSRect, cornerRadius radius: CGFloat) {
		self.init(roundedRect: aRect, xRadius: radius, yRadius: radius)
	}
}
