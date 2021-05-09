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
	static let prevNextTouch = NSTouchBarItem.Identifier("com.ToWatchList.prevNextButton")
}

@available(macOS 10.12.2, *)
extension TSSTSessionWindowController: NSTouchBarDelegate {
	open override func makeTouchBar() -> NSTouchBar? {
		let touchBar = NSTouchBar()
		touchBar.delegate = self
//		touchBar.customizationIdentifier = .touchBar
		touchBar.defaultItemIdentifiers = [.prevNextTouch, NSTouchBarItem.Identifier.otherItemsProxy]
		touchBar.customizationAllowedItemIdentifiers = [.prevNextTouch]
		
		return touchBar
	}

	public func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
		switch identifier {
		case .prevNextTouch:
			let item = NSCustomTouchBarItem(identifier: .prevNextTouch)
			item.customizationLabel = NSLocalizedString("Prev/Next Comic", comment: "Prev/Next TouchBar Comic")
			
			let prevNext = NSSegmentedControl(images: [NSImage(named: NSImage.touchBarGoBackTemplateName)!, NSImage(named: NSImage.touchBarGoForwardTemplateName)!], trackingMode: .momentary, target: self, action: #selector(self.touchBarPrevNextAction(_:)))
			
			item.view = prevNext
			
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
}
