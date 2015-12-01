//
//  TSSTInfoWindow.swift
//  SimpleComic
//
//  Created by C.W. Betts on 12/1/15.
//  Copyright © 2015 Dancing Tortoise Software. All rights reserved.
//

import AppKit

final class TSSTInfoView : NSView {
	var bordered: Bool = false
	var caretPosition: CGFloat = 0 {
		didSet {
			needsDisplay = true
		}
	}

	override func drawRect(dirtyRect: NSRect) {
		let bounds = self.bounds
		NSColor.clearColor().set()
		NSRectFill(bounds)
		
		let outline = NSBezierPath()
		outline.moveToPoint(NSPoint(x: caretPosition + 5, y: 5))
		outline.lineToPoint(NSPoint(x: caretPosition, y: 0))
		outline.lineToPoint(NSPoint(x: caretPosition - 5, y: 5))
		outline.appendBezierPathWithArcFromPoint(NSPoint(x: 0, y: 5),
			toPoint: NSPoint(x: 0, y: bounds.midY),
			radius: 5)
		outline.appendBezierPathWithArcFromPoint(NSPoint(x: 0, y: bounds.maxY),
			toPoint: NSPoint(x: bounds.midX, y: bounds.maxY),
			radius: 5)
		outline.appendBezierPathWithArcFromPoint(NSPoint(x: bounds.maxX, y: bounds.maxY),
			toPoint: NSPoint(x: bounds.maxX, y: bounds.midY),
			radius: 5)
		outline.appendBezierPathWithArcFromPoint(NSPoint(x: bounds.maxX, y: 5),
			toPoint: NSPoint(x: caretPosition + 5, y: 5),
			radius: 5)
		outline.closePath()
		NSColor(calibratedWhite: 1, alpha: 1).set()
		outline.fill()
	}
}
