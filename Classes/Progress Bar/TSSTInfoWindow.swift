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
	override init(contentRect: NSRect, styleMask aStyle: NSWindow.StyleMask, backing bufferingType: NSWindow.BackingStoreType, defer flag: Bool) {
		super.init(contentRect: contentRect, styleMask: .borderless, backing: bufferingType, defer: flag)
		isOpaque = false
		ignoresMouseEvents = true
		backgroundColor = NSColor.clear
	}
	
	@objc(caretAtPoint:size:withLimitLeft:right:)
	func caret(at point: NSPoint, size: NSSize, limitLeft left: CGFloat, limitRight right: CGFloat) {
		let limitWidth = right - left
		let relativePosition = (point.x - left) / limitWidth
		let offset = size.width * relativePosition
		let frameRect = NSRect(x: point.x - offset - 10, y: point.y, width: size.width + 20, height: size.height + 25)
		(contentView as? TSSTInfoView)?.caretPosition = offset + 10
		setFrame(frameRect, display: true, animate: false)
		invalidateShadow()
	}
	
	@objc(centerAtPoint:)
	func center(at center: NSPoint) {
		let frame = self.frame
		let fo = NSPoint(x: center.x - frame.width / 2, y: center.y - frame.height / 2)
		setFrameOrigin(fo)
		invalidateShadow()
	}
	
	@objc(resizeToDiameter:)
	func resize(toDiameter diameter: CGFloat) {
		let frame = self.frame
		let center = NSPoint(x: frame.minX + frame.width / 2, y: frame.minY + frame.height / 2)
		setFrame(NSRect(x: center.x - diameter / 2, y: center.y - diameter / 2, width: diameter, height: diameter),
				 display: true,
				 animate: false)
	}
}
