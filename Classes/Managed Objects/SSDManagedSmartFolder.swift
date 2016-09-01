//
//  SSDManagedSmartFolder.swift
//  SimpleComic
//
//  Created by C.W. Betts on 5/22/16.
//  Copyright © 2016 Dancing Tortoise Software. All rights reserved.
//

import Cocoa

class ManagedSmartFolder: TSSTManagedGroup {
	fileprivate var metadataSemaphore = DispatchSemaphore(value: 0)
	
	func smartFolderContents() {
		let fm = FileManager()
		var pageSet = Set<TSSTPage>()
		var fileNames = [String]()
		
		guard let filePath = value(forKey: "path") as? NSString as? String , fm.fileExists(atPath: filePath) else {
			NSLog("Failed path");
			return;
		}
		do {
			guard let dic = NSDictionary(contentsOfFile: filePath), let result = dic.object(forKey: "RawQuery") as? NSObject else {
				return;
			}
			//print(result.description)
			
			func useTask() {
				let pipe = Pipe()
				let file = pipe.fileHandleForReading
				
				let task = Process()
				
				task.launchPath = "/usr/bin/mdfind";
				task.arguments = [result.description];
				task.standardOutput = pipe;
				
				task.launch()
				
				let data = file.readDataToEndOfFile()
				guard let resultString = String(data: data, encoding: String.Encoding.utf8) else {
					return
				}
				fileNames = resultString.components(separatedBy: "\n")
			}
			
			if let rawQuery = dic.object(forKey: "RawQueryDict") as? NSDictionary as? [String: AnyObject],
				let mdStr = result as? String,
				let mdPred = NSPredicate(fromMetadataQueryString: mdStr) {
				
				let query = NSMetadataQuery()
				let nf = NotificationCenter.default
				nf.addObserver(self, selector: #selector(ManagedSmartFolder.queryNote(_:)), name: nil, object: query)
				defer {
					nf.removeObserver(self, name: nil, object: query)
				}

				let emailExclusionPredicate = NSPredicate(format:"(kMDItemContentType != 'com.apple.mail.emlx') && (kMDItemContentType != 'public.vcard')");
				let predicateToRun: NSPredicate = NSCompoundPredicate(andPredicateWithSubpredicates:[mdPred, emailExclusionPredicate]);

				query.predicate = predicateToRun
				query.searchScopes = (rawQuery["SearchScopes"] as? [AnyObject]) ?? []
				query.delegate = self
				//Move it to a seperate thread so it actually works.
				query.operationQueue = OperationQueue()
				query.start()
				
				if metadataSemaphore.wait(timeout: DispatchTime.now() + DispatchTimeInterval.seconds(4)) == .timedOut {
					let objPtr = Unmanaged.passUnretained(self).toOpaque()
					let objWhutPtr = objPtr.assumingMemoryBound(to: Void.self)
					NSLog(String(format:"%@: %p We ran out of time! Using NSTask using mdfind.", self.className, objWhutPtr))
					useTask()
				} else {
					query.stop()
					fileNames = query.results.filter({ (anObj) -> Bool in
						return anObj is NSString
					}) as? [NSString] as? [String] ?? []
				}
				
			} else {
				useTask()
			}
		}
		
		var pageNumber = 0
		
		for path in fileNames {
			let pathExtension = (path as NSString).pathExtension.lowercased()
			// Handles recognized image files
			if TSSTPage.imageExtensions().contains(pathExtension) {
				var imageDescription: TSSTPage

				imageDescription = NSEntityDescription.insertNewObject(forEntityName: "Image", into: managedObjectContext!) as! TSSTPage
				imageDescription.setValue("\(path)", forKey: "imagePath")
				imageDescription.setValue(pageNumber, forKey: "index")
				pageSet.insert(imageDescription)
				pageNumber += 1;
			} else if TSSTManagedArchive.archiveExtensions().contains(pathExtension) {
				//NSManagedObject * nestedDescription;
				let nestedDescription = NSEntityDescription.insertNewObject(forEntityName: "Archive", into: managedObjectContext!) as! TSSTManagedArchive
				nestedDescription.setValue(path, forKey: "path")
				nestedDescription.setValue(path, forKey: "name")
				nestedDescription.nestedArchiveContents()
				nestedDescription.setValue(self, forKey: "group")
			} else if pathExtension == "pdf" {
				let nestedDescription = NSEntityDescription.insertNewObject(forEntityName: "PDF", into: managedObjectContext!) as! TSSTManagedPDF
				nestedDescription.setValue(path, forKey: "path")
				nestedDescription.setValue(path, forKey: "name")
				nestedDescription.pdfContents()
				nestedDescription.setValue(self, forKey: "group")
			}
		}
		
		setValue(pageSet, forKey: "images")
	}
	
	override func data(forPageIndex index: Int) -> Data? {
		guard let images = self.value(forKey: "images") as? NSSet as? Set<TSSTPage> else {
			return nil
		}
		var filepath: String? = nil;
		
		for page in images {
			guard let integer = page.value(forKey: "index") as? NSNumber else {
				continue
			}
			if integer.intValue == index {
				filepath = page.value(forKey: "imagePath") as? NSString as? String
			}
		}
		
		
		// TODO: add check to see if file exist?
		guard let filePath = filepath else {
			return nil
		}
		
		return (try? Data(contentsOf: URL(fileURLWithPath: filePath)))
	}
}

extension ManagedSmartFolder: NSMetadataQueryDelegate {
	func metadataQuery(_ query: NSMetadataQuery, replacementObjectForResultObject result: NSMetadataItem) -> Any {
		return result.value(forAttribute: kMDItemPath as String) as? NSString ?? NSNull()
	}
	
	@objc fileprivate func queryNote(_ note: Notification) {
		if note.name == NSNotification.Name.NSMetadataQueryDidFinishGathering {
			metadataSemaphore.signal()
		}
	}
}
