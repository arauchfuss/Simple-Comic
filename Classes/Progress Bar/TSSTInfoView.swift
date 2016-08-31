//
//  TSSTInfoWindow.swift
//  SimpleComic
//
//  Created by C.W. Betts on 12/1/15.
//  Copyright © 2015 Dancing Tortoise Software. All rights reserved.
//

import Cocoa

final class TSSTInfoView : NSView {
	var bordered: Bool = false
	var caretPosition: CGFloat = 0 {
		didSet {
			needsDisplay = true
		}
	}

	override func draw(_ dirtyRect: NSRect) {
		let bounds = self.bounds
		NSColor.clear.set()
		NSRectFill(bounds)
		
		let outline = NSBezierPath()
		outline.move(to: NSPoint(x: caretPosition + 5, y: 5))
		outline.line(to: NSPoint(x: caretPosition, y: 0))
		outline.line(to: NSPoint(x: caretPosition - 5, y: 5))
		outline.appendArc(from: NSPoint(x: 0, y: 5),
			to: NSPoint(x: 0, y: bounds.midY),
			radius: 5)
		outline.appendArc(from: NSPoint(x: 0, y: bounds.maxY),
			to: NSPoint(x: bounds.midX, y: bounds.maxY),
			radius: 5)
		outline.appendArc(from: NSPoint(x: bounds.maxX, y: bounds.maxY),
			to: NSPoint(x: bounds.maxX, y: bounds.midY),
			radius: 5)
		outline.appendArc(from: NSPoint(x: bounds.maxX, y: 5),
			to: NSPoint(x: caretPosition + 5, y: 5),
			radius: 5)
		outline.close()
		NSColor(calibratedWhite: 1, alpha: 1).set()
		outline.fill()
	}
}
