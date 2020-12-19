//
//  DTWindowCategory.swift
//  Simple Comic
//
//  Created by J-rg on 21.11.20.
//  Copyright © 2020 Dancing Tortoise Software. All rights reserved.
//

import Cocoa

@objc
extension NSWindow {
	
	var toolbarHeight: CGFloat {
		get {
			return frame.height - contentRect(forFrameRect: frame).height
		}
	}
	
	var isFullscreen: Bool {
		get {
			return styleMask.contains(.fullScreen)
		}
	}
}
