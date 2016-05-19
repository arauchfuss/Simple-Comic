//
//  TSSTBezelWindow.swift
//  SimpleComic
//
//  Created by C.W. Betts on 10/26/15.
//  Copyright 2015 Dancing Tortoise Software. All rights reserved.
//

import Cocoa

class TSSTBezelWindow : NSPanel {
	override init(contentRect rect: NSRect, styleMask aStyle: Int, backing bufferingType: NSBackingStoreType, `defer` flag: Bool) {
		super.init(contentRect: rect, styleMask: NSBorderlessWindowMask, backing: bufferingType, defer: flag)
	}

	required init?(coder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	override var canBecomeKeyWindow: Bool {
		return true
	}
	
	override func performClose(sender: AnyObject?) {
		delegate?.windowShouldClose?(self)
	}
	
	override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
		return menuItem.action == #selector(TSSTBezelWindow.performClose(_:)) ? true : false
	}
}
