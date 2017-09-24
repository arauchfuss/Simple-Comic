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

	Simple Comic
	TSSTTransparentView.swift
*/
//
//  TSSTTransparentView.swift
//  SimpleComic
//
//  Created by C.W. Betts on 10/26/15.
//  Copyright © 2015 Dancing Tortoise Software. All rights reserved.
//

import Cocoa

class TSSTTransparentView: NSView {
	override func draw(_ rect: NSRect) {
		NSColor(calibratedWhite: 0, alpha: 0.7).set()
		rect.fill()
	}
}
