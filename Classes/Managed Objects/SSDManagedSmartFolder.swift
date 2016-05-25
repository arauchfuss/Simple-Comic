//
//  SSDManagedSmartFolder.swift
//  SimpleComic
//
//  Created by C.W. Betts on 5/22/16.
//  Copyright © 2016 Dancing Tortoise Software. All rights reserved.
//

import Cocoa

@objc(SSDManagedSmartFolder)
class ManagedSmartFolder: TSSTManagedGroup {
	private var metadataSemaphore = dispatch_semaphore_create(0)
	
	func smartFolderContents() {
		let fm = NSFileManager()
		var pageSet = Set<TSSTPage>()
		var fileNames = [String]()
		
		guard let filePath = valueForKey("path") as? NSString as? String where fm.fileExistsAtPath(filePath) else {
			NSLog("Failed path");
			return;
		}
		do {
			guard let dic = NSDictionary(contentsOfFile: filePath), result = dic.objectForKey("RawQuery") as? NSObject else {
				return;
			}
			print(result.description)
			
			func useTask() {
				let pipe = NSPipe()
				let file = pipe.fileHandleForReading
				
				let task = NSTask()
				
				task.launchPath = "/usr/bin/mdfind";
				task.arguments = [result.description];
				task.standardOutput = pipe;
				
				task.launch()
				
				let data = file.readDataToEndOfFile()
				guard let resultString = String(data: data, encoding: NSUTF8StringEncoding) else {
					return
				}
				fileNames = resultString.componentsSeparatedByString("\n")
			}
			
			if let rawQuery = dic.objectForKey("RawQueryDict") as? NSDictionary as? [String: AnyObject],
				mdStr = result as? String,
				mdPred = NSPredicate(fromMetadataQueryString: mdStr) {
				
				let query = NSMetadataQuery()
				let nf = NSNotificationCenter.defaultCenter()
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
				query.operationQueue = NSOperationQueue()
				query.startQuery()
				
				if dispatch_semaphore_wait(metadataSemaphore, dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC * 4))) != 0 {
					NSLog("%@: %p We ran out of time! Using NSTask using mdfind.", self.className, unsafeAddressOf(self))
					useTask()
				} else {
					query.stopQuery()
					fileNames = query.results as? [NSString] as? [String] ?? []
				}
				
			} else {
				useTask()
			}
		}
		
		var pageNumber = 0
		
		for path in fileNames {
			let pathExtension = (path as NSString).pathExtension.lowercaseString
			NSLog("path: %@  -  extension: %@", path, pathExtension);
			// Handles recognized image files
			if TSSTPage.imageExtensions().contains(pathExtension) {
				var imageDescription: TSSTPage

				imageDescription = NSEntityDescription.insertNewObjectForEntityForName("Image", inManagedObjectContext: managedObjectContext!) as! TSSTPage
				imageDescription.setValue("\(path)", forKey: "imagePath")
				imageDescription.setValue(pageNumber, forKey: "index")
				pageSet.insert(imageDescription)
				pageNumber += 1;
			} else if TSSTManagedArchive.archiveExtensions().contains(pathExtension){
				//NSManagedObject * nestedDescription;
				let nestedDescription = NSEntityDescription.insertNewObjectForEntityForName("Archive", inManagedObjectContext: managedObjectContext!) as! TSSTManagedArchive
				nestedDescription.setValue(path, forKey: "path")
				nestedDescription.setValue(path, forKey: "name")
				nestedDescription.nestedArchiveContents()
				nestedDescription.setValue(self, forKey: "group")
			} else if pathExtension == "pdf" {
				let nestedDescription = NSEntityDescription.insertNewObjectForEntityForName("PDF", inManagedObjectContext: managedObjectContext!) as! TSSTManagedPDF
				nestedDescription.setValue(path, forKey: "path")
				nestedDescription.setValue(path, forKey: "name")
				nestedDescription.pdfContents()
				nestedDescription.setValue(self, forKey: "group")
			}
		}
		
		setValue(pageSet, forKey: "images")
	}
	
	override func dataForPageIndex(index: Int) -> NSData? {
		guard let images = self.valueForKey("images") as? NSSet as? Set<TSSTPage> else {
			return nil
		}
		var filepath: String? = nil;
		
		for page in images {
			guard let integer = page.valueForKey("index") as? NSNumber else {
				continue
			}
			if integer == index {
				filepath = page.valueForKey("imagePath") as? NSString as? String
			}
		}
		
		
		// TODO: add check to see if file exist?
		guard let filePath = filepath else {
			return nil
		}
		
		return NSData(contentsOfFile: filePath)
	}
}

extension ManagedSmartFolder: NSMetadataQueryDelegate {
	func metadataQuery(query: NSMetadataQuery, replacementObjectForResultObject result: NSMetadataItem) -> AnyObject {
		return result.valueForAttribute(kMDItemPath as String) ?? NSNull()
	}
	
	@objc private func queryNote(note: NSNotification) {
		if note.name == NSMetadataQueryDidFinishGatheringNotification {
			dispatch_semaphore_signal(metadataSemaphore)
		}
	}
}
