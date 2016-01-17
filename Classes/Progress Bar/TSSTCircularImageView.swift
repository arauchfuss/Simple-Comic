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
			let loupeGradient = NSGradient(startingColor: NSColor(calibratedWhite: 0.30, alpha: 1), endingColor: NSColor(calibratedWhite: 0.60, alpha: 1))
			let centerPoint = centerPointOfRect(dirtyRect)
			loupeGradient?.drawFromCenter(centerPoint, radius: dirtyRect.width / 2 - 10, toCenter: centerPoint, radius: dirtyRect.width / 2 - 1, options: 0)
			var circle = NSBezierPath(ovalInRect: bounds.insetBy(dx: 1, dy: 1))
			NSColor(calibratedWhite: 0.2, alpha: 2).set()
			circle.lineWidth = 2
			circle.stroke()
			circle = NSBezierPath(ovalInRect: bounds.insetBy(dx: 10, dy: 10))
			NSColor.whiteColor().set()
			circle.fill()
			circle.addClip()
			super.drawRect(dirtyRect)
			NSColor(calibratedWhite: 0.6, alpha: 1).set()
			circle.lineWidth = 3
			circle.stroke()
		}
	}
}
