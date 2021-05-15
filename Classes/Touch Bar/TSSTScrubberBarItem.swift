//
//  TSSTScrubberBarItem.swift
//  Simple Comic
//
//  Created by C.W. Betts on 5/15/21.
//  Copyright © 2021 Dancing Tortoise Software. All rights reserved.
//

import Cocoa

@available(macOS 10.12.2, *)
class TSSTScrubberBarItem: NSCustomTouchBarItem, NSScrubberDelegate, NSScrubberFlowLayoutDelegate {
	
	static let itemViewIdentifier = NSUserInterfaceItemIdentifier("TSSTImageItemViewIdentifier")
	
	var scrubberItemWidth: Int = 50
	weak var sessionController: TSSTSessionWindowController?
	
	func scrubber(_ scrubber: NSScrubber, didChangeVisibleRange visibleRange: NSRange) {
		guard let range = Range<Int>(visibleRange) else {
			print("Bad range \(visibleRange)")
			return
		}
		for i in range {
			if let thumbnailItem = scrubber.itemViewForItem(at: i) as? TSSTThumbnailItemView {
				thumbnailItem.generateThumbnail()
			}
		}
	}

	func scrubber(_ scrubber: NSScrubber, layout: NSScrubberFlowLayout, sizeForItemAt itemIndex: Int) -> NSSize {
		return NSSize(width: scrubberItemWidth, height: 30)
	}
	
	func scrubber(_ scrubber: NSScrubber, didSelectItemAt index: Int) {
		sessionController?.pageController?.setSelectionIndex(index)
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}
	
	override init(identifier: NSTouchBarItem.Identifier) {
		super.init(identifier: identifier)
		
		let scrubber = NSScrubber()
		scrubber.register(TSSTThumbnailItemView.self, forItemIdentifier: TSSTScrubberBarItem.itemViewIdentifier)
		scrubber.mode = .free
		scrubber.selectionBackgroundStyle = .roundedBackground
		scrubber.delegate = self
		
		view = scrubber
	}
}
