//
//  TSSTThumbnailItemView.swift
//  Simple Comic
//
//  Created by C.W. Betts on 5/15/21.
//  Copyright © 2021 Dancing Tortoise Software. All rights reserved.
//

import Cocoa

@available(macOS 10.12.2, *)
class TSSTThumbnailItemView: NSScrubberItemView {
	private let imageView: NSImageView
	private let spinner: NSProgressIndicator
	var page: TSSTPage?
	private var loaded = false

	private var thumbnail: NSImage {
		didSet {
			spinner.isHidden = true
			spinner.stopAnimation(nil)
			imageView.isHidden = false
			imageView.image = thumbnail
		}
	}

	required override init(frame frameRect: NSRect) {
		thumbnail = NSImage(size: frameRect.size)
		imageView = NSImageView(image: thumbnail)
		imageView.autoresizingMask = [.width, .height]
		spinner = NSProgressIndicator()
		
		super.init(frame: frameRect)
		
		spinner.isIndeterminate = true
		spinner.style = .spinning
		spinner.sizeToFit()
		spinner.frame = bounds.insetBy(dx: (bounds.width - spinner.frame.width) / 2, dy: (bounds.height - spinner.frame.height) / 2)
		spinner.isHidden = true
		spinner.controlSize = .small
		spinner.appearance = NSAppearance(named: .vibrantDark)
		spinner.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxXMargin]
		
		subviews = [imageView, spinner]
	}
	
	required init?(coder: NSCoder) {
		// The system always creates this particular view class programmatically.
		fatalError("init(coder:) has not been implemented")
	}

	override func updateLayer() {
		layer?.backgroundColor = NSColor.controlColor.cgColor
	}
	
	override func layout() {
		super.layout()
		
		imageView.frame = bounds
		spinner.sizeToFit()
		spinner.frame = bounds.insetBy(dx: (bounds.width - spinner.frame.width) / 2, dy: (bounds.height - spinner.frame.height) / 2)
	}
	
	func generateThumbnail() {
		guard !loaded else {
			return
		}
		loaded = true
		spinner.isHidden = false
		spinner.startAnimation(nil)
		imageView.isHidden = true
		
		DispatchQueue.global(qos: .background).async { [self] in
			guard let fullImage = page?.thumbnail else {
				DispatchQueue.main.async {
					self.thumbnail = NSImage(size: .zero)
				}
				
				return
			}
			
			let imageSize = fullImage.size
			let thumbnailHeight: CGFloat = 30
			let thumbnailSize = NSSize(width: max(ceil(thumbnailHeight * imageSize.width / imageSize.height), 50), height: thumbnailHeight)
			let fromRect: NSRect
			if thumbnailSize.width == 50 {
				// shortcut: thumbnails are constrained to 256 points
				let cutImage: CGFloat = imageSize.width / thumbnailSize.width * thumbnailHeight
				fromRect = NSRect(x: 0, y: imageSize.height - cutImage, width: imageSize.width, height: cutImage)
			} else {
				fromRect = NSRect(origin: .zero, size: imageSize)
			}
			
			let thumbnail = NSImage(size: thumbnailSize)
			thumbnail.lockFocus()
			fullImage.draw(in: NSRect(origin: .zero, size: thumbnailSize),
						   from: fromRect,
						   operation: .sourceOver,
						   fraction: 1.0)
			thumbnail.unlockFocus()
			
			DispatchQueue.main.async {
				self.thumbnail = thumbnail
			}
		}
	}
}
