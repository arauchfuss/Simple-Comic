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
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
 OTHER DEALINGS IN THE SOFTWARE.
 
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

/**
Configurable progress bar.  Allows the setting of various style attributes.
Progress direction can be set.
*/
class DTPolishedProgressBar : NSView {
	
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
progressFill: This is the gradient of the filled portion of the pr ituogress bar.
shadow:  This is the gradient that give the illusion of depth.
textStyle: Dictionary of string attributes.
*/

	/// The direction of the porgress bar.
	dynamic var leftToRight: Bool = true {
		didSet {
			needsDisplay = true
		}
	}
	/// The maximum value of the progress bar.
	dynamic var maxValue: Int = 0 {
		didSet {
			needsDisplay = true
		}
	}
	/// The progress bar is filled to this level.
	dynamic var currentValue: Int = 0 {
		didSet {
			needsDisplay = true
		}
	}

	/// This is the section of the view. Users can mouse over and click here.
	var progressRect = NSRect()
	
	/// How much room is given for the text on either side.
	var horizontalMargin: CGFloat = 5

	/// The font attributes of the progress numbers.
	var numberStyle: [String: AnyObject] = [NSFontAttributeName: NSFont.systemFontOfSize(10),
	NSForegroundColorAttributeName: NSColor(deviceWhite: 0.2, alpha: 1)]

	/// Translates a point within the view to an index between `0` and `maxValue`.<br>
	/// Progress indicator direction affects the index.
	func indexForPoint(point: NSPoint) -> Int {
		var index: Int
		if leftToRight {
			index = Int((point.x - NSMinX(progressRect)) / NSWidth(progressRect) * CGFloat(maxValue))
		} else {
			index = Int((NSMaxX(progressRect) - point.x) / NSWidth(progressRect) * CGFloat(maxValue))
		}
		index = index >= maxValue ? maxValue - 1 : index;
		return index;
	}

	override func drawRect(dirtyRect: NSRect) {
		let totalString = String(maxValue)
		let progressString = String(currentValue + 1)
		let leftString: String
		let rightString: String
		
		let bounds = self.bounds
		var indicatorRect = NSMakeRect(0, bounds.height - 9, 2, 9)
		let barRect = NSMakeRect(0, bounds.height - 5, bounds.width, 5)
		var fillRect: NSRect
		
		var leftSize: NSSize
		var rightSize: NSSize
		
		// Draw background
		backgroundColor.set()
		NSRectFillUsingOperation(bounds, .CompositeSourceOver)
		
		// Draw bar background
		barBackgroundColor.set()
		fillRect = barRect
		NSRectFill(fillRect)
		
		// Determine label positions and progress rect size+position
		if leftToRight {
			fillRect.size.width = NSWidth(bounds) * CGFloat(currentValue + 1) / CGFloat(maxValue)
			indicatorRect.origin.x = round(NSWidth(fillRect)-2);
			
			leftString = progressString;
			rightString = totalString;
		} else {
			fillRect.size.width = NSWidth(bounds) * CGFloat(currentValue + 1) / CGFloat(maxValue)
			fillRect.origin.x = round(NSWidth(bounds) - NSWidth(fillRect));
			indicatorRect.origin.x = NSMinX(fillRect);
			
			leftString = totalString;
			rightString = progressString;
		}
		
		leftSize = leftString.sizeWithAttributes(numberStyle)
		leftSize.width = ceil(leftSize.width)
		rightSize = rightString.sizeWithAttributes(numberStyle)
		rightSize.width = ceil(rightSize.width)
		
		// Draw progress
		barProgressColor.set()
		NSRectFill(fillRect);

		// Draw indicator
		NSColor.blackColor().set()
		NSRectFill(indicatorRect);

		// Draw labels
		let leftStringRect = NSMakeRect(horizontalMargin, NSMinY(bounds), leftSize.width, 17);
		leftString.drawInRect(leftStringRect, withAttributes: numberStyle)
		
		let rightStringRect = NSMakeRect(NSWidth(bounds) - self.horizontalMargin - rightSize.width, NSMinY(bounds), rightSize.width, 17);
		rightString.drawInRect(rightStringRect, withAttributes: numberStyle)

		// Draw borders
		let leftBorder = NSMakeRect(0, 0, 1, NSHeight(bounds));
		let rightBorder = NSMakeRect(NSWidth(bounds)-1, 0, 1, NSHeight(bounds));

		borderColor.set()
		
		NSRectFillUsingOperation(leftBorder, .CompositeSourceOver);
		NSRectFillUsingOperation(rightBorder, .CompositeSourceOver);
	}
	
	/// This method has been over-ridden to change the progressRect porperty every time the
	/// progress view is re-sized.
	override func setFrameSize(size: NSSize) {
		self.progressRect = NSRect(origin: .zero, size: size)
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
	
	override func mouseDown(theEvent: NSEvent) {
		let cursorPoint = convertPoint(theEvent.locationInWindow, fromView: nil)
		if NSMouseInRect( cursorPoint, progressRect, flipped){
			self.currentValue = indexForPoint(cursorPoint)
		}
	}
	
	override func mouseDragged(theEvent: NSEvent) {
		let cursorPoint = convertPoint(theEvent.locationInWindow, fromView: nil)
		if NSMouseInRect(cursorPoint, progressRect, flipped) {
			self.currentValue = indexForPoint(cursorPoint)
			
			NSNotificationCenter.defaultCenter().postNotificationName("SCMouseDragNotification", object: self)
		}
	}
	
	deinit {
		removeTrackingArea(trackingAreas[0])
	}
}
