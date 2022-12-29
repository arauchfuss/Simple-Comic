//
//  PartialArchiveParser.swift
//  QuickComic Thumbnailer
//
//  Created by C.W. Betts on 12/15/22.
//  Copyright © 2022 Dancing Tortoise Software. All rights reserved.
//

import Foundation
import XADMaster
import XADMaster.XADString
import XADMaster.XADArchiveParser

internal class PartialArchiveParser: NSObject, XADArchiveParserDelegate {
	private(set) var searchResult: Data? = nil
	private let searchString: String
	
	init(with url:URL, searchString: String) throws {
		self.searchString = searchString
		super.init()
		let parser = try XADArchiveParser.archiveParser(for: url)
		parser.delegate = self
		do {
			try parser.parse()
		} catch XADError.break {
			
		}
	}
	
	
	func archiveParser(_ parser: XADArchiveParser, foundEntryWith dict: [XADArchiveKeys : Any]) throws {
		let resnum = dict[.isResourceFork] as? Bool
		let isRes = resnum ?? false
		searchResult = nil
		
		guard !isRes else {
			return
		}
		let name = dict[.fileName] as? XADStringProtocol
		let encodedName = name?.string(with: parser.encodingName)
		if searchString == encodedName {
			let handle = try parser.handleForEntry(with: dict, wantChecksum: true)
			searchResult = try handle.remainingFileContents()
			if handle.hasChecksum && !handle.isChecksumCorrect {
				throw XADError(.checksum)
			}
		}
	}
	
	func archiveParsingShouldStop(_ parser: XADArchiveParser) -> Bool {
		return searchResult != nil
	}
}
