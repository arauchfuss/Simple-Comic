//
//  TSSTSessionWindowController+NSTouchBar.swift
//  Simple Comic
//
//  Created by C.W. Betts on 5/8/21.
//  Copyright © 2021 Dancing Tortoise Software. All rights reserved.
//

import Cocoa

@available(macOS 10.12.2, *)
extension NSTouchBarItem.Identifier {
	static let prevNext = NSTouchBarItem.Identifier("com.ToWatchList.prevNextButton")
	static let pageOrder = NSTouchBarItem.Identifier("com.ToWatchList.pageOrder")
	static let pageLayout = NSTouchBarItem.Identifier("com.ToWatchList.pageLayout")
	static let pageScaling = NSTouchBarItem.Identifier("com.ToWatchList.pageScaling")
	static let rotate = NSTouchBarItem.Identifier("com.ToWatchList.rotatePage")
	static let scrubber = NSTouchBarItem.Identifier("com.ToWatchList.scrubberBar")
}

@available(macOS 10.12.2, *)
extension NSTouchBar.CustomizationIdentifier {
	static let touchBar = "com.ToWatchList.touchBar"
}

@available(macOS 10.12.2, *)
extension TSSTSessionWindowController: NSTouchBarDelegate, NSScrubberDataSource {
	open override func makeTouchBar() -> NSTouchBar? {
		let touchBar = NSTouchBar()
		touchBar.delegate = self
		touchBar.customizationIdentifier = .touchBar
		touchBar.defaultItemIdentifiers = [.prevNext, .scrubber, .pageOrder, NSTouchBarItem.Identifier.otherItemsProxy]
		touchBar.customizationAllowedItemIdentifiers = [.prevNext, .pageOrder, .pageLayout, .rotate, .pageScaling, .scrubber, .flexibleSpace]
		
		return touchBar
	}

	public func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
		switch identifier {
		case .prevNext:
			let item = NSCustomTouchBarItem(identifier: .prevNext)
			item.customizationLabel = NSLocalizedString("Prev/Next Comic", comment: "Prev/Next TouchBar Comic")
			
			let prevNext = NSSegmentedControl(images: [NSImage(named: NSImage.touchBarGoBackTemplateName)!, NSImage(named: NSImage.touchBarGoForwardTemplateName)!], trackingMode: .momentary, target: self, action: #selector(self.touchBarPrevNextAction(_:)))
			
			item.view = prevNext
			
			return item
			
		case .pageOrder:
			let item = NSCustomTouchBarItem(identifier: .pageOrder)
			item.customizationLabel = NSLocalizedString("520.label", tableName: "TSSTSessionWindow", comment: "Page Order")

			let prevNext = NSSegmentedControl(images: [NSImage(named: "rightLeftOrderTemplate")!, NSImage(named: "leftRightOrderTemplate")!], trackingMode: .selectOne, target: nil, action: nil)
			prevNext.bind(.selectedIndex, to: self, withKeyPath: "session.pageOrder", options: nil)
			
			item.view = prevNext
			
			return item

		case .pageLayout:
			let item = NSCustomTouchBarItem(identifier: .pageLayout)
			item.customizationLabel = NSLocalizedString("523.label", tableName: "TSSTSessionWindow", comment: "Page Layout")

			let prevNext = NSSegmentedControl(images: [NSImage(named: "onePageTemplate")!, NSImage(named: "twoPageTemplate")!], trackingMode: .selectOne, target: nil, action: nil)
			prevNext.bind(.selectedIndex, to: self, withKeyPath: "session.twoPageSpread", options: nil)
			
			item.view = prevNext
			
			return item

		case .pageScaling:
			let item = NSCustomTouchBarItem(identifier: .pageScaling)
			item.customizationLabel = NSLocalizedString("517.label", tableName: "TSSTSessionWindow", comment: "Page Scaling")

			let prevNext = NSSegmentedControl(images: [NSImage(named: "equalTemplate")!, NSImage(named: "winScaleTemplate")!, NSImage(named: "horScaleTemplate")!], trackingMode: .selectOne, target: nil, action: nil)
			prevNext.bind(.selectedIndex, to: self, withKeyPath: "session.scaleOptions", options: nil)
			
			item.view = prevNext
			
			return item

		case .rotate:
			let item = NSCustomTouchBarItem(identifier: .rotate)
			item.customizationLabel = NSLocalizedString("585.label", tableName: "TSSTSessionWindow", comment: "Rotate")
			
			let prevNext = NSSegmentedControl(images: [NSImage(named: NSImage.touchBarRotateLeftTemplateName)!, NSImage(named: NSImage.touchBarRotateRightTemplateName)!], trackingMode: .momentary, target: self, action: #selector(self.rotate(_:)))
			if #available(macOS 10.13, *) {
				prevNext.setTag(901, forSegment: 0)
				prevNext.setTag(902, forSegment: 1)
			} else {
				(prevNext.cell as? NSSegmentedCell)?.setTag(901, forSegment: 0)
				(prevNext.cell as? NSSegmentedCell)?.setTag(902, forSegment: 1)
			}

			item.view = prevNext
			
			return item
			
		case .scrubber:
			let item = TSSTScrubberBarItem(identifier: .scrubber)
			item.customizationLabel = NSLocalizedString("Scrubber", comment: "Scrubber")
			item.sessionController = self
			(item.view as! NSScrubber).dataSource = self
//			(item.view as! NSScrubber).bind(.selectedIndex, to: self, withKeyPath: "selectionIndex", options: nil)
			return item

		default:
			return nil
		}
	}
	
	@IBAction func touchBarPrevNextAction(_ sender: NSSegmentedControl) {
		switch sender.selectedSegment {
		case 0:
			pageLeft(nil)
			
		case 1:
			pageRight(nil)
			
		default:
			break
		}
	}
	
	public func numberOfItems(for scrubber: NSScrubber) -> Int {
		return (pageController!.arrangedObjects as! NSArray).count
	}
	
	public func scrubber(_ scrubber: NSScrubber, viewForItemAt index: Int) -> NSScrubberItemView {
		var returnItemView = NSScrubberItemView()
		if let itemView =
			scrubber.makeItem(withIdentifier: TSSTScrubberBarItem.itemViewIdentifier,
							  owner: nil) as? TSSTThumbnailItemView {
			let item = (pageController!.arrangedObjects as! NSArray).object(at: index) as? TSSTPage
			itemView.page = item
			
			returnItemView = itemView
		}
		return returnItemView
	}
}
