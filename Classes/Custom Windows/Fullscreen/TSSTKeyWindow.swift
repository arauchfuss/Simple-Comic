/*
	Copyright (c) 2006-2009 Dancing Tortoise Software
 
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
	
	Simple Comic
	TSSTKeyWindow.swift
*/
//
//  TSSTKeyWindow.swift
//  SimpleComic
//
//  Created by C.W. Betts on 10/26/15.
//  Copyright 2015 Dancing Tortoise Software. All rights reserved.
//

import Cocoa

class TSSTKeyWindow : NSPanel {
	override init(contentRect rect: NSRect, styleMask aStyle: NSWindowStyleMask, backing bufferingType: NSBackingStoreType, defer flag: Bool) {
		super.init(contentRect: rect, styleMask: NSBorderlessWindowMask, backing: bufferingType, defer: flag)
		isOpaque = false
	}
	
	override var canBecomeKey: Bool {
		return true
	}
	
	override func performClose(_ sender: Any?) {
		_ = delegate?.windowShouldClose?(self)
	}
	
	override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
		return menuItem.action == #selector(TSSTKeyWindow.performClose(_:)) ? true : false
	}
}
