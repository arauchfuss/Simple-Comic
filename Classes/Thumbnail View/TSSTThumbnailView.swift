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
	
	@objc weak var dataSource: TSSTSessionWindowController?
	
	private var trackingRects = IndexSet()
	private var trackingIndexes = Set<NSNumber>()
	
	private var hoverIndex: Int? = nil
	private var limit = 0
	
	private var thumbLock = NSLock()
	private var threadIdent: UInt32 = 0

	override func awakeFromNib() {
		super.awakeFromNib()
		self.window?.makeFirstResponder(self)
		self.window?.acceptsMouseMovedEvents = true
		thumbnailView.clears = true
	}
	
	private func rect(for index: Int) -> NSRect {
		var bounds = window!.screen!.visibleFrame
		let fullBounds = window!.screen!.frame
		bounds.origin.x -= fullBounds.origin.x
		bounds.origin.y -= fullBounds.origin.y
		let ratio = bounds.height / bounds.width
		let horCount = Int(ceil(sqrt(CGFloat((pageController!.content! as AnyObject).count) / ratio)))
		let vertCount = Int(ceil(CGFloat((pageController!.content! as AnyObject).count) / CGFloat(horCount)))
		let side = bounds.height / CGFloat(vertCount)
		let horSide = bounds.width / CGFloat(horCount)
		let horGridPos = index % horCount
		let vertGridPos = (index / horCount) % vertCount
		let thumbRect: NSRect
		if dataSource!.session.pageOrder {
			thumbRect = NSRect(x: CGFloat(horGridPos) * horSide, y: bounds.maxY - side - CGFloat(vertGridPos) * side, width: horSide, height: side)
		}
		else {
			thumbRect = NSRect(x: bounds.maxX - horSide - CGFloat(horGridPos) * horSide, y: bounds.maxY - side - CGFloat(vertGridPos) * side, width: horSide, height: side)
		}
		return thumbRect
	}
	
	private func removeTrackingRects() {
		thumbnailView.image = nil
		hoverIndex = nil
		
		for tagIndex in trackingRects.reversed() {
			self.removeTrackingRect(tagIndex)
		}
		trackingRects.removeAll()
		trackingIndexes.removeAll()
	}
	
	@objc func buildTrackingRects() {
		hoverIndex = nil
		removeTrackingRects()
		var trackRect: NSRect
		var rectIndex: NSNumber
		for counter in 0 ..< (pageController!.content! as AnyObject).count {
			trackRect = rect(for: counter).insetBy(dx: 2, dy: 2)
			rectIndex = NSNumber(value: counter)
			let tagIndex = addTrackingRect(trackRect, owner: self, userData: Unmanaged.passUnretained(rectIndex).toOpaque(), assumeInside: false)
			trackingRects.insert(tagIndex)
			trackingIndexes.insert(rectIndex)
		}
		needsDisplay = true
	}
	
	@objc func processThumbs() {
		autoreleasepool() {
			threadIdent += 1
			let localIdent = threadIdent
			thumbLock.lock()
			let pageCount: Int = (pageController!.content! as AnyObject).count
			limit = 0
			while limit < (pageCount) && localIdent == threadIdent &&
				dataSource?.responds(to: #selector(TSSTSessionWindowController.imageForPage(at:))) ?? false {
				autoreleasepool() {
					dataSource!.imageForPage(at: limit)
					if (limit % 5) == 0 {
						DispatchQueue.main.async {
							if self.window!.isVisible {
								self.needsDisplay = true
							}
						}
					}
					limit += 1
				}
			}
			thumbLock.unlock()
		}
		DispatchQueue.main.sync {
			needsDisplay = true
		}
	}
	
	override func draw(_ rect: NSRect) {
		let mousePoint = convert(window!.mouseLocationOutsideOfEventStream, from: nil)
		for counter in 0 ..< limit {
			let thumbnail = dataSource!.imageForPage(at: counter)
			var drawRect = self.rect(for: counter)
			drawRect = rectCentered(with: thumbnail.size, in: drawRect.insetBy(dx: 2, dy: 2))
			thumbnail.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1.0)
			if NSMouseInRect(mousePoint, drawRect, false) {
				hoverIndex = counter
				zoomThumbnail(at: hoverIndex!)
			}
		}
	}
	
	override func mouseEntered(with theEvent: NSEvent) {
		hoverIndex = unsafeBitCast(theEvent.userData, to: NSNumber.self).intValue
		if limit == (pageController.content! as AnyObject).count {
			Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(TSSTThumbnailView.dwell(_:)), userInfo: (hoverIndex! as NSNumber), repeats: false)
		}
	}
	
	override func mouseExited(with theEvent: NSEvent) {
		if unsafeBitCast(theEvent.userData, to: NSNumber.self).intValue == hoverIndex {
			hoverIndex = nil
			thumbnailView.image = nil
			window!.removeChildWindow(thumbnailView.window!)
			thumbnailView.window!.orderOut(self)
		}
	}
	
	@objc private func dwell(_ timer: Timer) {
		if let userInfo = timer.userInfo as? NSNumber,
			let hoverIndex = hoverIndex,
			userInfo.intValue == hoverIndex {
			zoomThumbnail(at: hoverIndex)
		}
	}

	private func zoomThumbnail(at index: Int) {
		guard let arrangedObject = (pageController.arrangedObjects as? NSArray)?[index] as? NSObject,
			let thumb = arrangedObject.value(forKey: "pageImage") as? NSImage else {
			assert(false, "could not get image at index \(index)")
			return
		}
		thumbnailView.image = thumb
		thumbnailView.needsDisplay = true
		
		var imageSize = thumb.size
		thumbnailView.imageName = arrangedObject.value(forKey: "name") as? String
		let indexRect = rect(for: index)
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
			thumbPoint.y = visibleRect.maxY - imageSize.height / 2
		}
		else if thumbPoint.y - imageSize.height / 2 < visibleRect.minY {
			thumbPoint.y = visibleRect.minY + imageSize.height / 2
		}
		
		if thumbPoint.x + imageSize.width / 2 > visibleRect.maxX {
			thumbPoint.x = visibleRect.maxX - imageSize.width / 2
		} else if thumbPoint.x - imageSize.width / 2 < visibleRect.minX {
			thumbPoint.x = visibleRect.minX + imageSize.width / 2
		}
		
		thumbPoint.x -= imageSize.width / 2
		thumbPoint.y -= imageSize.height / 2
		(thumbnailView.window as! TSSTInfoWindow).setFrame(NSRect(origin: thumbPoint, size: imageSize), display: false, animate: false)
		window?.addChildWindow(thumbnailView.window!, ordered: .above)
	}
	
	override func mouseDown(with theEvent: NSEvent) {
		if let hoverIndex = hoverIndex, hoverIndex < (pageController.content! as AnyObject).count && hoverIndex >= 0 {
			pageController.setSelectionIndex(hoverIndex)
		}
		window?.orderOut(self)
	}
	
	override func keyDown(with theEvent: NSEvent) {
		guard let chars = theEvent.charactersIgnoringModifiers else {
			return
		}
		
		if let nsChar = chars.utf16.first, nsChar == 27 {
			(window!.windowController! as! TSSTSessionWindowController).killTopOptionalUIElement()
		}
	}
}
