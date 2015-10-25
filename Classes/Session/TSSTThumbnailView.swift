//
//  TSSTThumbnailView.swift
//  SimpleComic
//
//  Created by C.W. Betts on 10/25/15.
//
//

import Cocoa

class TSSTThumbnailView: NSView {
	@IBOutlet weak var pageController: NSArrayController!
	@IBOutlet weak var thumbnailView: TSSTImageView!
	
	weak var dataSource: TSSTSessionWindowController?
	
	private let trackingRects = NSMutableIndexSet()
	private var trackingIndexes = Set<NSNumber>()
	
	private var hoverIndex: Int? = nil
	private var limit = 0
	
	private var thumbLock = NSLock()
	private var threadIdent: UInt32 = 0;

	override func awakeFromNib() {
		super.awakeFromNib()
		self.window?.makeFirstResponder(self)
		self.window?.acceptsMouseMovedEvents = true
		thumbnailView.clears = true
	}
	
	func rectForIndex(index: Int) -> NSRect {
		let bounds = window!.screen!.visibleFrame
		let ratio = bounds.height / bounds.width
		let horCount = Int(ceil(sqrt(CGFloat(pageController!.content!.count) / ratio)))
		let vertCount = Int(ceil(CGFloat(pageController!.content!.count) / CGFloat(horCount)))
		let side = bounds.height / CGFloat(vertCount)
		let horSide = bounds.width / CGFloat(horCount)
		let horGridPos = index % horCount
		let vertGridPos = (index / horCount) % vertCount
		let thumbRect: NSRect
		if dataSource!.session?.valueForKey("pageOrder")?.boolValue ?? false {
			thumbRect = NSMakeRect(CGFloat(horGridPos) * horSide, NSMaxY(bounds) - side - CGFloat(vertGridPos) * side, horSide, side)
		}
		else {
			thumbRect = NSMakeRect(NSMaxX(bounds) - horSide - CGFloat(horGridPos) * horSide, NSMaxY(bounds) - side - CGFloat(vertGridPos) * side, horSide, side)
		}
		return thumbRect
	}
	
	func removeTrackingRects() {
		thumbnailView.image = nil
		hoverIndex = nil
		var tagIndex: Int = trackingRects.lastIndex
		while tagIndex != NSNotFound {
			self.removeTrackingRect(tagIndex)
			tagIndex = trackingRects.indexLessThanIndex(tagIndex)
		}
		trackingRects.removeAllIndexes()
		trackingIndexes.removeAll()
	}
	
	func buildTrackingRects() {
		hoverIndex = nil
		removeTrackingRects()
		var trackRect: NSRect
		var rectIndex: NSNumber
		for counter in 0 ..< pageController!.content!.count {
			trackRect = rectForIndex(counter).insetBy(dx: 2, dy: 2)
			rectIndex = counter
			let tagIndex = addTrackingRect(trackRect, owner: self, userData: UnsafeMutablePointer(unsafeAddressOf(rectIndex)), assumeInside: false)
			trackingRects.addIndex(tagIndex)
			trackingIndexes.insert(rectIndex)
		}
		needsDisplay = true
	}
	
	func processThumbs() {
		autoreleasepool() {
			++threadIdent
			let localIdent = threadIdent
			thumbLock.lock()
			let pageCount: Int = pageController!.content!.count
			limit = 0
			while limit < (pageCount) && localIdent == threadIdent && dataSource!.respondsToSelector("imageForPageAtIndex:") {
				autoreleasepool() {
					dataSource!.imageForPageAtIndex(limit)
					if (limit % 5) == 0 {
						if window!.visible {
							needsDisplay = true
						}
					}
					++limit
				}
			}
			thumbLock.unlock()
		}
		needsDisplay = true
	}
	
	override func drawRect(rect: NSRect) {
		var counter: Int = 0
		var mousePoint: NSPoint = window!.convertRectFromScreen(NSRect(origin: NSEvent.mouseLocation(), size: .zero)).origin
		mousePoint = convertPoint(mousePoint, fromView: nil)
		while counter < limit {
			let thumbnail = dataSource!.imageForPageAtIndex(counter)
			var drawRect = self.rectForIndex(counter)
			drawRect = rectWithSizeCenteredInRect(thumbnail.size, NSInsetRect(drawRect, 2, 2))
			thumbnail.drawInRect(drawRect, fromRect: NSZeroRect, operation: .CompositeSourceOver, fraction: 1.0)
			if NSMouseInRect(mousePoint, drawRect, false) {
				hoverIndex = counter
				zoomThumbnailAtIndex(hoverIndex!)
			}
			++counter
		}
	}
	
	override func mouseEntered(theEvent: NSEvent) {
		hoverIndex = unsafeBitCast(theEvent.userData, NSNumber.self).integerValue
		if limit == pageController.content?.count {
			NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: "dwell:", userInfo: (hoverIndex! as NSNumber), repeats: false)
		}
	}
	
	override func mouseExited(theEvent: NSEvent) {
		if unsafeBitCast(theEvent.userData, NSNumber.self).integerValue == hoverIndex {
			hoverIndex = nil
			thumbnailView.image = nil
			window!.removeChildWindow(thumbnailView.window!)
			thumbnailView.window!.orderOut(self)
		}
	}
	
	func dwell(timer: NSTimer) {
		if let userInfo = timer.userInfo as? NSNumber, hoverIndex = hoverIndex where userInfo == hoverIndex {
			zoomThumbnailAtIndex(hoverIndex)
		}
	}

	func zoomThumbnailAtIndex(index: Int) {
		guard let arrangedObject = (pageController.arrangedObjects as? NSArray)?[index] as? NSObject, thumb = arrangedObject.valueForKey("pageImage") as? NSImage else {
			assert(false, "could not get image at index \(index)")
			return
		}
		thumbnailView.image = thumb
		thumbnailView.needsDisplay = true
		
		var imageSize = thumb.size
		thumbnailView.imageName = arrangedObject.valueForKey("pageImage") as? String
		let indexRect = rectForIndex(index)
		let visibleRect = window!.screen!.visibleFrame
		var thumbPoint = NSPoint(x: indexRect.minX + indexRect.width / 2, y: indexRect.minY + indexRect.height / 2)
		let viewSize: CGFloat = 312 //[thumbnailView frame].size.width;
		let aspect = imageSize.width / imageSize.height
		
		if aspect <= 1 {
			imageSize = NSSize(width: aspect * viewSize, height: viewSize)
		} else {
			imageSize = NSSize(width: viewSize, height: viewSize / aspect)
		}
		
		if thumbPoint.y + imageSize.height / 2 > visibleRect.maxY {
			thumbPoint.y = visibleRect.maxY - imageSize.height / 2;
		}
		else if thumbPoint.y - imageSize.height / 2 < visibleRect.minY {
			thumbPoint.y = visibleRect.minY + imageSize.height / 2;
		}
		
		if thumbPoint.x + imageSize.width / 2 > visibleRect.maxX {
			thumbPoint.x = visibleRect.maxX - imageSize.width / 2;
		} else if thumbPoint.x - imageSize.width / 2 < visibleRect.minX {
			thumbPoint.x = visibleRect.minX + imageSize.width / 2;
		}
		
		thumbPoint.x -= imageSize.width / 2
		thumbPoint.y -= imageSize.height / 2
		(thumbnailView.window as! TSSTInfoWindow).setFrame(NSRect(origin: thumbPoint, size: imageSize), display: false, animate: false)
		window?.addChildWindow(thumbnailView.window!, ordered: .Above)
	}
	
	override func mouseDown(theEvent: NSEvent) {
		if let hoverIndex = hoverIndex where hoverIndex < pageController.content!.count && hoverIndex >= 0 {
			pageController.setSelectionIndex(hoverIndex)
		}
		window?.orderOut(self)
	}
	
	override func keyDown(theEvent: NSEvent) {
		guard let chars = theEvent.charactersIgnoringModifiers else {
			return
		}
		
		let nsChar = (chars as NSString).characterAtIndex(0)
		if nsChar == 27 {
			(window!.windowController! as! TSSTSessionWindowController).killTopOptionalUIElement()
		}
	}
}
