/*
 Copyright (c) 2006-2009 Dancing Tortoise Software
 Created by Alexander Rauchfuss

 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or
 sell copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:

 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.

 DTPolishedProgressBar.swift
*/
//
//  Created by C.W. Betts on 10/24/15.
//

import Cocoa

private let backgroundColor = NSColor(calibratedRed: 1, green: 1, blue: 1, alpha: 0.55)
private let barBackgroundColor = NSColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1)
private let barProgressColor = NSColor(deviceRed: 0.44, green: 0.44, blue: 0.44, alpha: 1)
private let borderColor = NSColor(red:0, green: 0, blue: 0, alpha: 0.25)

/// The font attributes of the progress numbers.
private let numberStyle: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 10),
														 .foregroundColor: NSColor(deviceWhite: 0.2, alpha: 1)]


/**
Configurable progress bar. Allows the setting of various style attributes.
Progress direction can be set.
*/
class DTPolishedProgressBar: NSView {

	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		setFrameSize(frameRect.size)
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setFrameSize(frame.size)
	}

/*
List of replacements for the highcontrast flag
Highlight: NSColor if nil then layout is slightly shifted.
barFill: This is the gradient of the empty portion of the progress bar
progressFill: This is the gradient of the filled portion of the progress bar.
shadow: This is the gradient that give the illusion of depth.
textStyle: Dictionary of string attributes.
*/

	/// The direction of the progress bar.
	@IBInspectable
	dynamic var leftToRight: Bool = true {
		didSet {
			needsDisplay = true
		}
	}
	/// The maximum value of the progress bar.
	@IBInspectable
	dynamic var maxValue: Int = 0 {
		didSet {
			needsDisplay = true
		}
	}
	/// The progress bar is filled to this level.
	@IBInspectable
	dynamic var currentValue: Int = 0 {
		didSet {
			needsDisplay = true
		}
	}
	
	/// This is the section of the view. Users can mouse over and click here.
	@objc private(set) var progressRect = NSRect()
	
	/// How much room is given for the text on either side.
	private var horizontalMargin: CGFloat = 5

	/// Translates a point within the view to an index between `0` and `maxValue`.
	/// Progress indicator direction affects the index.
	@objc(indexForPoint:) func index(for point: NSPoint) -> Int {
		var index: Int
		if leftToRight {
			index = Int((point.x - progressRect.minX) / progressRect.width * CGFloat(maxValue))
		} else {
			index = Int((progressRect.maxX - point.x) / progressRect.width * CGFloat(maxValue))
		}
		index = index >= maxValue ? maxValue - 1 : index
		// Because maxValue might be 0, making index = -1
		guard index >= 0 else {
			return 0
		}
		return index
	}

	/// Draws the progressbar.
	override func draw(_ dirtyRect: NSRect) {
		let totalString = String(maxValue)
		let progressString = String(currentValue + 1)
		let leftString: String
		let rightString: String
		
		let bounds2 = self.bounds
		var indicatorRect = NSMakeRect(0, bounds2.height - 9, 2, 9)
		let barRect = NSMakeRect(0, bounds2.height - 5, bounds2.width, 5)
		
		// Draw background
		backgroundColor.set()
		bounds2.fill(using: .sourceOver)
		
		// Draw bar background
		barBackgroundColor.set()
		var fillRect = barRect
		fillRect.fill()
		
		// Determine label positions and progress rect size+position
		if leftToRight {
			fillRect.size.width = bounds2.width * CGFloat(currentValue + 1) / CGFloat(maxValue)
			indicatorRect.origin.x = round(fillRect.width - 2)
			
			leftString = progressString
			rightString = totalString
		} else {
			fillRect.size.width = bounds2.width * CGFloat(currentValue + 1) / CGFloat(maxValue)
			fillRect.origin.x = round(bounds2.width - fillRect.width)
			indicatorRect.origin.x = fillRect.minX
			
			leftString = totalString
			rightString = progressString
		}
		
		let leftSize = leftString.size(withAttributes: numberStyle)
		let rightSize = rightString.size(withAttributes: numberStyle)
		
		// Draw progress
		barProgressColor.set()
		fillRect.fill()
		
		// Draw indicator
		NSColor.black.set()
		indicatorRect.fill()
		
		// Draw labels
		let leftStringRect = NSRect(x: horizontalMargin, y: bounds2.minY, width: leftSize.width, height: 17)
		leftString.draw(in: leftStringRect, withAttributes: numberStyle)
		
		let rightStringRect = NSRect(x: bounds2.width - horizontalMargin - rightSize.width, y: bounds2.minY, width: rightSize.width, height: 17)
		rightString.draw(in: rightStringRect, withAttributes: numberStyle)
		
		// Draw borders
		let leftBorder = NSRect(x: 0, y: 0, width: 1, height: bounds2.height)
		let rightBorder = NSRect(x: bounds2.width - 1, y: 0, width: 1, height: bounds2.height)
		
		borderColor.set()
		
		leftBorder.fill(using: .sourceOver)
		rightBorder.fill(using: .sourceOver)
	}
	
	/// This method has been over-ridden to change the progressRect porperty every time the
	/// progress view is re-sized.
	override func setFrameSize(_ size: NSSize) {
		progressRect = NSRect(origin: .zero, size: size)
		super.setFrameSize(size)
	}
	
	/// If there has been a mouse tracking area added to this view it will be updated
	/// every time the progress bar is re-sized.
	/// The tracking area is based on the `progressRect` property.
	override func updateTrackingAreas() {
		defer {
			super.updateTrackingAreas()
		}
		guard trackingAreas.count != 0 else {
			return
		}
		
		let oldArea = trackingAreas.first!
		removeTrackingArea(oldArea)
		
		let newArea = NSTrackingArea(rect: progressRect, options: oldArea.options, owner: oldArea.owner, userInfo: oldArea.userInfo)
		addTrackingArea(newArea)
	}
	
	override var mouseDownCanMoveWindow: Bool {
		return false
	}
	
	/// Changes the `currentValue` based on where the user clicks.
	override func mouseDown(with theEvent: NSEvent) {
		let cursorPoint = convert(theEvent.locationInWindow, from: nil)
		if NSMouseInRect(cursorPoint, progressRect, isFlipped) {
			self.currentValue = index(for: cursorPoint)
		}
	}
	
	/// Kind of surprised that the mouseDown event method would not refresh.
	/// Not enough code to be worth abstracting.
	override func mouseDragged(with theEvent: NSEvent) {
		let cursorPoint = convert(theEvent.locationInWindow, from: nil)
		if NSMouseInRect(cursorPoint, progressRect, isFlipped) {
			self.currentValue = index(for: cursorPoint)
			
			NotificationCenter.default.post(name: .TSSTMouseDrag, object: self)
		}
	}
	
	deinit {
		removeTrackingArea(trackingAreas[0])
	}
}
