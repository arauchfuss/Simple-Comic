//
//  CenteredTextLayer.swift
//  Simple Comic
//
//  Created by J-rg on 09.12.20.
//  Copyright © 2020 Dancing Tortoise Software. All rights reserved.
//

import QuartzCore

@objc
class CenteredTextLayer: CATextLayer {
	
	override func draw(in ctx: CGContext) {
		let height = bounds.size.height
		let fontSize = self.fontSize
		let yDiff = (height - fontSize) / 2 - fontSize / 10
		
		ctx.saveGState()
		ctx.translateBy(x: 0, y: -yDiff)
		super.draw(in: ctx)
		ctx.restoreGState()
	}
}
