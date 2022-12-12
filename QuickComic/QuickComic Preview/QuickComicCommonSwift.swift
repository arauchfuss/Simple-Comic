//
//  QuickComicCommonSwift.swift
//  QuickComic Preview
//
//  Created by C.W. Betts on 12/11/22.
//  Copyright © 2022 Dancing Tortoise Software. All rights reserved.
//

import Cocoa
import XADMaster
import UniformTypeIdentifiers


let fileSort: [NSSortDescriptor] = {
	let sort = TSSTSortDescriptor(key: "name", ascending: true)
	return [sort]
}()

private let imageFileTypes = {
	let imageTypes = NSImage.imageTypes
	var imageExtensions = Set<String>()
	for uti in imageTypes {
		if let aUT = UTType(uti),
		   let tmpExt = aUT.tags[.filenameExtension] {
			imageExtensions.formUnion(tmpExt)
		} else {
			if let filenameExtensions = UTTypeCopyAllTagsWithClass(uti as NSString, kUTTagClassFilenameExtension)?.takeRetainedValue(),
			   let fileUnwrapped = filenameExtensions as? [String] {
				imageExtensions.formUnion(fileUnwrapped)
			}
		}
	}
	return imageExtensions
}()

func fileList(for archive: XADArchive) -> [[String: Any]] {
	let numEntries = archive.numberOfEntries
	var fileDescriptions = [[String: Any]]()
	fileDescriptions.reserveCapacity(numEntries)
	
	for index in 0 ..< numEntries {
		if let fileName = archive.name(ofEntry: index),
		   let rawName = archive.name(ofEntry: index),
		   imageFileTypes.contains((fileName as NSString).pathExtension.lowercased()) {
			let fileDescription: [String : Any] = ["name": fileName,
												   "index": index,
												   "rawName": rawName]
			fileDescriptions.append(fileDescription)
		}
	}
	
	return fileDescriptions
}
