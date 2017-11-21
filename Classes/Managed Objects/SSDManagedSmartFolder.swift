//
//  SSDManagedSmartFolder.swift
//  SimpleComic
//
//  Created by C.W. Betts on 5/22/16.
//  Copyright © 2016 Dancing Tortoise Software. All rights reserved.
//

import Cocoa

class ManagedSmartFolder: TSSTManagedGroup {
	private var metadataSemaphore = DispatchSemaphore(value: 0)
	
	@objc func smartFolderContents() {
		let fm = FileManager()
		var pageSet = Set<TSSTPage>()
		var fileNames = [String]()
		
		let filePath = self.path
		guard fm.fileExists(atPath: filePath) else {
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
				guard let resultString = String(data: data, encoding: .utf8) else {
					return
				}
				fileNames = resultString.components(separatedBy: "\n")
			}
			
			if let rawQuery = dic.object(forKey: "RawQueryDict") as? NSDictionary as? [String: Any],
				let mdStr = result as? String,
				let mdPred = NSPredicate(fromMetadataQueryString: mdStr) {
				
				let query = NSMetadataQuery()
				let nf = NotificationCenter.default
				nf.addObserver(self, selector: #selector(ManagedSmartFolder.queryNote(_:)), name: nil, object: query)
				defer {
					nf.removeObserver(self, name: nil, object: query)
				}

				let emailExclusionPredicate = NSPredicate(format:"(kMDItemContentType != 'com.apple.mail.emlx') && (kMDItemContentType != '\(kUTTypeVCard as String)')");
				let predicateToRun: NSPredicate = NSCompoundPredicate(andPredicateWithSubpredicates:[mdPred, emailExclusionPredicate]);

				query.predicate = predicateToRun
				query.searchScopes = (rawQuery["SearchScopes"] as? [Any]) ?? []
				query.delegate = self
				//Move it to a seperate thread so it actually works.
				query.operationQueue = OperationQueue()
				query.start()
				
				if metadataSemaphore.wait(timeout: DispatchTime.now() + DispatchTimeInterval.seconds(4)) == .timedOut {
					query.stop()
					let objPtr = Unmanaged.passUnretained(self).toOpaque()
					let objWhutPtr = objPtr.assumingMemoryBound(to: Void.self)
					NSLog(String(format:"%@: %p We ran out of time! Using NSTask using mdfind.", self.className, objWhutPtr))
					useTask()
				} else {
					query.stop()
					fileNames = query.results.filter({ (anObj) -> Bool in
						return anObj is String
					}) as? [String] ?? []
				}
			} else {
				useTask()
			}
		}
		
		var pageNumber = 0
		let workspace = NSWorkspace.shared
		
		for path in fileNames.map({ return URL(fileURLWithPath: $0)}) {
			let pathExtension = path.pathExtension.lowercased()
			if let fileUTI = try? workspace.type(ofFile: path.path) {
				// Handles recognized image files
				if TSSTPage.imageTypes.contains(fileUTI) {
					let imageDescription = NSEntityDescription.insertNewObject(forEntityName: "Image", into: managedObjectContext!) as! TSSTPage
					imageDescription.imagePath = path.path
					imageDescription.index = pageNumber as NSNumber
					pageSet.insert(imageDescription)
					pageNumber += 1;
					continue
				} else if TSSTManagedArchive.archiveTypes.contains(fileUTI) {
					let nestedDescription = NSEntityDescription.insertNewObject(forEntityName: "Archive", into: managedObjectContext!) as! TSSTManagedArchive
					nestedDescription.name = path.path
					nestedDescription.fileURL = path
					nestedDescription.nestedArchiveContents()
					nestedDescription.group = self
					continue
				} else if UTTypeConformsTo(fileUTI as NSString, kUTTypePDF) {
					let nestedDescription = NSEntityDescription.insertNewObject(forEntityName: "PDF", into: managedObjectContext!) as! TSSTManagedPDF
					nestedDescription.name = path.path
					nestedDescription.fileURL = path
					nestedDescription.pdfContents()
					nestedDescription.group = self
					continue
				}
				//Fall through if we couldn't identify it via UTI
			}
			// Handles recognized image files
			if TSSTPage.imageExtensions.contains(pathExtension) {
				var imageDescription: TSSTPage

				imageDescription = NSEntityDescription.insertNewObject(forEntityName: "Image", into: managedObjectContext!) as! TSSTPage
				imageDescription.imagePath = path.path
				imageDescription.index = pageNumber as NSNumber
				pageSet.insert(imageDescription)
				pageNumber += 1;
			} else if TSSTManagedArchive.archiveExtensions.contains(pathExtension) {
				//NSManagedObject * nestedDescription;
				let nestedDescription = NSEntityDescription.insertNewObject(forEntityName: "Archive", into: managedObjectContext!) as! TSSTManagedArchive
				nestedDescription.name = path.path
				nestedDescription.fileURL = path
				nestedDescription.nestedArchiveContents()
				nestedDescription.group = self
			} else if pathExtension == "pdf" {
				let nestedDescription = NSEntityDescription.insertNewObject(forEntityName: "PDF", into: managedObjectContext!) as! TSSTManagedPDF
				nestedDescription.name = path.path
				nestedDescription.fileURL = path
				nestedDescription.pdfContents()
				nestedDescription.group = self
			}
		}
		
		self.images = pageSet
	}
	
	override func data(forPageIndex index: Int) -> Data? {
		guard let images = self.images else {
			return nil
		}
		var filepath: String? = nil;
		
		for page in images {
			guard let integer = page.index?.intValue else {
				continue
			}
			if integer == index {
				filepath = page.imagePath
				break
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
		guard let aResult = result.value(forAttribute: kMDItemPath as String) as? NSString else {
			return NSNull()
		}
		return aResult
	}
	
	@objc fileprivate func queryNote(_ note: Notification) {
		if note.name == NSNotification.Name.NSMetadataQueryDidFinishGathering {
			metadataSemaphore.signal()
		}
	}
}

extension ManagedSmartFolder {
	
	@nonobjc public class func fetchRequest() -> NSFetchRequest<ManagedSmartFolder> {
		return NSFetchRequest<ManagedSmartFolder>(entityName: "SmartFolder");
	}
}

