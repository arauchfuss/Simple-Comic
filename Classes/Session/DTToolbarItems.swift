//
//  DTToolbarItems.swift
//  Simple Comic
//
//  Created by J-rg on 09.12.20.
//  Copyright © 2020 Dancing Tortoise Software. All rights reserved.
//

import Cocoa

class DTToolbarItem: NSToolbarItem {
	
	override func validate() {
		guard let toolbarDelegate = toolbar?.delegate as? TSSTSessionWindowController else { return }
		
		if toolbarDelegate.responds(to: #selector(getter: TSSTSessionWindowController.pageSelectionInProgress)) {
			(view as? NSControl)?.isEnabled = !(toolbarDelegate.pageSelectionInProgress)
		}
	}
}

class DTPageTurnToolbarItem: DTToolbarItem {
	
	override func validate() {
		guard let toolbarDelegate = toolbar?.delegate as? TSSTSessionWindowController else { return }
		
		if toolbarDelegate.responds(to: #selector(getter: TSSTSessionWindowController.canTurnPageLeft)) {
			(view as? NSSegmentedControl)?.setEnabled(toolbarDelegate.canTurnPageLeft, forSegment: 0)
		}
		
		if toolbarDelegate.responds(to: #selector(getter: TSSTSessionWindowController.canTurnPageRight)) {
			(view as? NSSegmentedControl)?.setEnabled(toolbarDelegate.canTurnPageRight, forSegment: 1)
		}
		
		super.validate()
	}
}
