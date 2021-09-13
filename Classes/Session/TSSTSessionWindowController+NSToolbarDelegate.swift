//
//  TSSTSessionWindowController+NSToolbarDelegate.swift
//  Simple Comic
//
//  Created by J-rg on 13.09.21.
//  Copyright © 2021 Dancing Tortoise Software. All rights reserved.
//

import Cocoa

private extension NSToolbarItem.Identifier {
	static let turnPage    = NSToolbarItem.Identifier("ADD2836D-8728-474F-9355-80FA8EA9972C")
	static let pageOrder   = NSToolbarItem.Identifier("9C25BD8E-6129-4874-917D-C4C5F75BD24F")
	static let pageLayout  = NSToolbarItem.Identifier("57633342-20D2-433A-9828-1C85F79205A8")
	static let pageScaling = NSToolbarItem.Identifier("E33C7D17-8160-4B40-8EDF-78600C84FE8C")
	static let thumbnails  = NSToolbarItem.Identifier("AB4BCD46-EE79-45CC-9A97-733E3740BA34")
}

extension TSSTSessionWindowController: NSToolbarDelegate {
	
	public func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
		if #available(macOS 11.0, *) {
			return [
				.turnPage,
				.pageOrder,
				.pageLayout,
				.pageScaling,
				.flexibleSpace,
				.thumbnails,
			]
		} else {
			return [
				.turnPage,
				.space,
				.pageOrder,
				.pageLayout,
				.pageScaling,
				.flexibleSpace,
				.thumbnails,
			]
		}
	}
}
