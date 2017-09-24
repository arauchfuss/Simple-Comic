//
//  TSSTCircularImageView.swift
//  SimpleComic
//
//  Created by C.W. Betts on 1/17/16.
//  Copyright © 2016 Dancing Tortoise Software. All rights reserved.
//

import Cocoa

class TSSTCircularImageView: NSImageView {

	override func draw(_ dirtyRect: NSRect) {
		let bounds = self.bounds
		NSColor.clear.set()
		bounds.fill()
		if let _ = image {
			// Choose j-rg's flat magnifying glass over old one. Ported from j-rg's objective-c version.
			let circle = NSBezierPath(ovalIn: bounds.insetBy(dx: 5, dy: 5))
			NSColor.white.set()
			circle.fill()
			circle.addClip()
			super.draw(dirtyRect)
		}
	}
}
