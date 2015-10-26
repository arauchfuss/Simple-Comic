//
//  TSSTBezelView.swift
//  SimpleComic
//
//  Created by C.W. Betts on 10/26/15.
//  Copyright © 2015 Dancing Tortoise Software. All rights reserved.
//

import Cocoa

class TSSTBezelView : NSView {
	override func drawRect(aRect: NSRect) {
		NSColor.clearColor().set()
		NSRectFill(aRect)
		
		let polishedGradient = NSGradient(colorsAndLocations: (NSColor(deviceWhite: 0.3, alpha: 1), 0),
			(NSColor(deviceWhite: 0.25, alpha: 1), 0.5),
			(NSColor(deviceWhite: 0.2, alpha: 1), 0.5),
			(NSColor(deviceWhite: 1, alpha: 1), 1))
		
		polishedGradient?.drawInRect(bounds, angle: 270)
	}
}
