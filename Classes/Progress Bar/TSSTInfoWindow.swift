//
//  TSSTInfoWindow.swift
//  SimpleComic
//
//  Created by C.W. Betts on 1/17/16.
//  Copyright © 2016 Dancing Tortoise Software. All rights reserved.
//

import Cocoa

/// This panel subclass is used by both the loupe,
/// and the speech bubble styled page preview.
class TSSTInfoWindow: NSPanel {
	override init(contentRect: NSRect, styleMask aStyle: NSWindowStyleMask, backing bufferingType: NSBackingStoreType, defer flag: Bool) {
		super.init(contentRect: contentRect, styleMask: NSBorderlessWindowMask, backing: bufferingType, defer: flag)
		isOpaque = false
		ignoresMouseEvents = true

	}	
	
	func caretAtPoint(_ point: NSPoint, size: NSSize, withLimitLeft left: CGFloat, right: CGFloat) {
		let limitWidth = right - left
		let relativePosition = (point.x - left) / limitWidth
		let offset = size.width * relativePosition
		let frameRect = NSMakeRect( point.x - offset - 10, point.y, size.width + 20, size.height + 25)
		(contentView as? TSSTInfoView)?.caretPosition = offset + 10
		setFrame(frameRect, display: true, animate: false)
		invalidateShadow()
	}
	
	func centerAtPoint(_ center: NSPoint) {
		let frame = self.frame
		setFrameOrigin(NSPoint(x: center.x - frame.width / 2, y: center.y - frame.height / 2))
		invalidateShadow()
	}
	
	func resizeToDiameter(_ diameter: CGFloat) {
		let frame = self.frame
		let center = NSPoint(x: frame.minX + frame.width / 2, y: frame.minY + frame.height / 2)
		setFrame(NSRect(x: center.x - diameter / 2, y: center.y - diameter / 2, width: diameter, height: diameter),
			display: true,
			animate: false)
	}
}
