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
		NSRectFill(bounds)
		if let _ = image {
			let loupeGradient = NSGradient(starting: NSColor(calibratedWhite: 0.30, alpha: 1), ending: NSColor(calibratedWhite: 0.60, alpha: 1))
			let centerPoint = centerPointOfRect(dirtyRect)
			loupeGradient?.draw(fromCenter: centerPoint, radius: dirtyRect.width / 2 - 10, toCenter: centerPoint, radius: dirtyRect.width / 2 - 1, options: NSGradientDrawingOptions(rawValue: UInt(0)))
			var circle = NSBezierPath(ovalIn: bounds.insetBy(dx: 1, dy: 1))
			NSColor(calibratedWhite: 0.2, alpha: 2).set()
			circle.lineWidth = 2
			circle.stroke()
			circle = NSBezierPath(ovalIn: bounds.insetBy(dx: 10, dy: 10))
			NSColor.white.set()
			circle.fill()
			circle.addClip()
			super.draw(dirtyRect)
			NSColor(calibratedWhite: 0.6, alpha: 1).set()
			circle.lineWidth = 3
			circle.stroke()
		}
	}
}
