//
//  TSSTCircularImageView.swift
//  SimpleComic
//
//  Created by C.W. Betts on 1/17/16.
//  Copyright © 2016 Dancing Tortoise Software. All rights reserved.
//

import Cocoa

class TSSTCircularImageView: NSImageView {

	override func drawRect(dirtyRect: NSRect) {
		let bounds = self.bounds
		NSColor.clearColor().set()
		NSRectFill(bounds)
		if let _ = image {
			// Choose j-rg's flat magnifying glass over old one. Ported from j-rg's objective-c version.
			let circle = NSBezierPath(ovalInRect: NSInsetRect(bounds, 5, 5))
			NSColor.whiteColor().set()
			circle.fill()
			circle.addClip()
			super.drawRect(dirtyRect)

		}
	}
}
