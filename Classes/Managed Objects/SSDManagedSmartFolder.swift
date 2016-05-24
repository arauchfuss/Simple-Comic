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
	
	func smartFolderContents() {
		let fm = NSFileManager()
		var pageSet = Set<TSSTPage>()
		var fileNames = [String]()
		
		//TODO: replace NSTask with actual metadata calls.
		
		guard let filePath = valueForKey("path") as? NSString as? String where fm.fileExistsAtPath(filePath) else {
			NSLog("Failed path");
			return;
		}
		do {
			guard let dic = NSDictionary(contentsOfFile: filePath), result = dic.objectForKey("RawQuery") as? NSObject else {
				return;
			}
			print(result.description)
			
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
