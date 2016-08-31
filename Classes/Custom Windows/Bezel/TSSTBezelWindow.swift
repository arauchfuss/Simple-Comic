//
//  TSSTBezelWindow.swift
//  SimpleComic
//
//  Created by C.W. Betts on 10/26/15.
//  Copyright 2015 Dancing Tortoise Software. All rights reserved.
//

import Cocoa

class TSSTBezelWindow : NSPanel {
	override init(contentRect rect: NSRect, styleMask aStyle: NSWindowStyleMask, backing bufferingType: NSBackingStoreType, defer flag: Bool) {
		super.init(contentRect: rect, styleMask: NSBorderlessWindowMask, backing: bufferingType, defer: flag)
	}

	override var canBecomeKey: Bool {
		return true
	}
	
	override func performClose(_ sender: Any?) {
		_ = delegate?.windowShouldClose?(self)
	}
	
	func validate(_ menuItem: NSMenuItem) -> Bool {
		return menuItem.action == #selector(TSSTBezelWindow.performClose(_:)) ? true : false
	}
}
