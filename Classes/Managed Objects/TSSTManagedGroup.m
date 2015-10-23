//
//  TSSTManagedGroup.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 6/2/07.
//  Copyright 2007 Dancing Tortoise Software. All rights reserved.



#import "TSSTManagedGroup.h"
#import "SimpleComicAppDelegate.h"
#import <XADMaster/XADArchive.h>
#import <Quartz/Quartz.h>
#import "TSSTImageUtilities.h"
#import "TSSTPage.h"

@implementation TSSTManagedGroup


- (void)awakeFromInsert
{
	[super awakeFromInsert];
    groupLock = [NSLock new];
    instance = nil;
}


- (void)awakeFromFetch
{
	[super awakeFromFetch];
    groupLock = [NSLock new];
    instance = nil;

}


- (void)willTurnIntoFault
{
	NSError * error = nil;
	if([[self valueForKey: @"nested"] boolValue])
	{
		if(![[NSFileManager defaultManager] removeItemAtPath: [self valueForKey: @"path"] error: &error])
		{
			NSLog(@"%@",[error localizedDescription]);
		}
	}
}


- (void)didTurnIntoFault
{	
	instance = nil;
	groupLock = nil;
}



- (void)setPath:(NSString *)newPath
{
    NSError * urlError = nil;
    NSURL * fileURL = [[NSURL alloc] initFileURLWithPath: newPath];
    NSData * bookmarkData = [fileURL bookmarkDataWithOptions: NSURLBookmarkCreationMinimalBookmark
                              includingResourceValuesForKeys: nil
                                               relativeToURL: nil
                                                       error: &urlError];
    if (bookmarkData == nil || urlError != nil) {
        bookmarkData = nil;
        [NSApp presentError: urlError];
    }
	[self setValue: bookmarkData forKey: @"pathData"];
}



- (NSString *)path
{
    NSError * urlError = nil;
    BOOL stale = NO;
    NSURL * fileURL = [NSURL URLByResolvingBookmarkData: [self valueForKey: @"pathData"]
                                                options: NSURLBookmarkResolutionWithoutUI
                                          relativeToURL: nil
                                    bookmarkDataIsStale: &stale
                                                  error: &urlError];
    
    
	NSString * hardPath = nil;
    
    if (fileURL == nil || urlError != nil) {
        fileURL = nil;
        [[self managedObjectContext] deleteObject: self];
        [NSApp presentError: urlError];
    }
    else {
        hardPath = [fileURL path];
    }
	
	return hardPath;
}



- (id)instance
{
    return nil;
}



- (NSData *)dataForPageIndex:(NSInteger)index
{
    return nil;
}

- (NSData *)dataForPageName:(NSString *)name
{
    
    return nil;
}


- (NSManagedObject *)topLevelGroup
{
	return self;
}


/**
 Goes through various files like pdfs, images, text files
 from the path folder and it's subfolders and add these
 to the Core Data for the managedObjectContext
 with the info needed to deal with the files.
 */


- (void)nestedFolderContents
{
	NSString * folderPath = [self valueForKey: @"path"];
	NSFileManager * fileManager = [NSFileManager defaultManager];
	NSManagedObject * nestedDescription;
	NSError * error = nil;
	NSArray<NSString*> * nestedFiles = [fileManager contentsOfDirectoryAtPath: folderPath error: &error];
	if (error) {
		NSLog(@"%@",[error localizedDescription]);
	}
	NSString * path, * fileExtension, * fullPath;
	BOOL isDirectory, exists;
	
	for (path in nestedFiles)
	{
		nestedDescription = nil;
		fileExtension = [[path pathExtension] lowercaseString];
		fullPath = [folderPath stringByAppendingPathComponent: path];
		exists = [fileManager fileExistsAtPath: fullPath isDirectory: &isDirectory];
		if(exists && ![[[path lastPathComponent] substringToIndex: 1] isEqualToString: @"."])
		{
			if(isDirectory)
			{
				nestedDescription = [NSEntityDescription insertNewObjectForEntityForName: @"ImageGroup" inManagedObjectContext: [self managedObjectContext]];
			 	[nestedDescription setValue: fullPath forKey: @"path"];
		 		[nestedDescription setValue: path forKey: @"name"];
	 			[(TSSTManagedGroup *)nestedDescription nestedFolderContents];
			}
			else if([[TSSTManagedArchive archiveExtensions] containsObject: fileExtension])
			{
				nestedDescription = [NSEntityDescription insertNewObjectForEntityForName: @"Archive" inManagedObjectContext: [self managedObjectContext]];
				[nestedDescription setValue: fullPath forKey: @"path"];
				[nestedDescription setValue: path forKey: @"name"];
				[(TSSTManagedArchive *)nestedDescription nestedArchiveContents];
			}
			else if([fileExtension isEqualToString: @"pdf"])
 			{
				nestedDescription = [NSEntityDescription insertNewObjectForEntityForName: @"PDF" inManagedObjectContext: [self managedObjectContext]];
				[nestedDescription setValue: fullPath forKey: @"path"];
				[nestedDescription setValue: path forKey: @"name"];
				[(TSSTManagedPDF *)nestedDescription pdfContents];
			}
			else if([[TSSTPage imageExtensions] containsObject: fileExtension])
			{
				nestedDescription = [NSEntityDescription insertNewObjectForEntityForName: @"Image" inManagedObjectContext: [self managedObjectContext]];
				[nestedDescription setValue: fullPath forKey: @"imagePath"];
			}
			else if ([[TSSTPage textExtensions] containsObject: fileExtension])
			{
				nestedDescription = [NSEntityDescription insertNewObjectForEntityForName: @"Image" inManagedObjectContext: [self managedObjectContext]];
				[nestedDescription setValue: fullPath forKey: @"imagePath"];
				[nestedDescription setValue: @YES forKey: @"text"];
			}
            
			if(nestedDescription)
			{
				[nestedDescription setValue: self forKey: @"group"];
			}
		}
	}
}

/**
 Returns a set with all the images found in the key in union with the ones from other groups.
 
 @return NSSet with all images found in context.
*/
- (NSSet *)nestedImages
{
	NSMutableSet * allImages = [[NSMutableSet alloc] initWithSet: [self valueForKey: @"images"]];
	NSSet * groups = [self valueForKey: @"groups"];
	for(NSManagedObject * group in groups)
	{
		[allImages unionSet: [group valueForKey: @"nestedImages"]];
	}
	
	return allImages;
}


@end


@implementation TSSTManagedArchive

/**
 * @returns NSArray with archieve extions which the software supports.
 */
+ (NSArray *)archiveExtensions
{
	static NSArray * extensions = nil;
	if(!extensions)
	{
		extensions = @[@"rar", @"cbr", @"zip", @"cbz", @"7z", @"cb7", @"lha", @"lzh"];
	}
	
	return extensions;
}

/**
 @return NSArray with file extensions for which software support QuickLook for.
 */
+ (NSArray *)quicklookExtensions
{
	static NSArray * extensions = nil;

	if(!extensions)
	{
		extensions = @[@"cbr", @"cbz"];
	}
	
	return extensions;
}


- (void)willTurnIntoFault
{
	NSError * error;
	if([[self valueForKey: @"nested"] boolValue])
	{
		if(![[NSFileManager defaultManager] removeItemAtPath: [self valueForKey: @"path"] error: &error])
		{
			NSLog(@"%@",[error localizedDescription]);
		}
	}
	
	NSString * solid  = [self valueForKey: @"solidDirectory"];
	if(solid)
	{
		if(![[NSFileManager defaultManager] removeItemAtPath: solid error: &error])
		{
			NSLog(@"%@",[error localizedDescription]);
		}
	}
}



- (id)instance
{
    if (!instance)
    {
        NSFileManager * manager = [NSFileManager defaultManager];
        if([manager fileExistsAtPath: [self valueForKey: @"path"]])
        {
            instance = [[XADArchive alloc] initWithFile: [self valueForKey: @"path"] delegate: self error:NULL];

            // Set the archive delegate so that password and encoding queries can have a modal pop up.
			
            if([self valueForKey: @"password"])
            {
                [instance setPassword: [self valueForKey: @"password"]];
            }
        }
    }
	
    return instance;
}



- (NSData *)dataForPageIndex:(NSInteger)index
{
	NSString * solidDirectory = [self valueForKey: @"solidDirectory"];
	NSData * imageData;
	if(!solidDirectory)
	{
		[groupLock lock];
		imageData = [[self instance] contentsOfEntry: index];
		[groupLock unlock];
	}
	else
	{
		NSString * name = [[self instance] nameOfEntry: index];
		NSString * fileName = [NSString stringWithFormat:@"%li.%@", (long)index, [name pathExtension]];
		fileName = [solidDirectory stringByAppendingPathComponent: fileName];
		if(![[NSFileManager defaultManager] fileExistsAtPath: fileName])
		{
			[groupLock lock];
			imageData = [[self instance] contentsOfEntry: index];
			[groupLock unlock];
			[imageData writeToFile: fileName options: 0 error: nil];
		}
		else
		{
			imageData = [NSData dataWithContentsOfFile: fileName];
		}
	}

    return imageData;
}

- (NSData *)dataForPageName:(NSString *)name
{
    
    return nil;
}


- (NSManagedObject *)topLevelGroup
{
	NSManagedObject * group = self;
	NSManagedObject * parentGroup = group;
	
	while(group)
	{
		group = [group valueForKeyPath: @"group"];
		parentGroup = group && [group class] == [TSSTManagedArchive class] ? group : parentGroup;
	}
	
	return parentGroup;
}



- (void)nestedArchiveContents
{
    XADArchive * imageArchive = [self valueForKey: @"instance"];
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
	NSData * fileData;
	int collision = 0;
    TSSTManagedGroup * nestedDescription;
    NSString * extension, * archivePath = nil;
	NSString * fileName = nil;
	int counter, archivedFilesCount = [imageArchive numberOfEntries];
	NSError * error;
	if([imageArchive isSolid])
	{
		do {
			archivePath = [NSString stringWithFormat: @"SC-images-%i", collision];
			archivePath = [NSTemporaryDirectory() stringByAppendingPathComponent: archivePath];
			++collision;
		} while (![fileManager createDirectoryAtPath: archivePath withIntermediateDirectories: YES attributes: nil error: &error]);
		[self setValue: archivePath forKey: @"solidDirectory"];
	}
    
    for (counter = 0; counter < archivedFilesCount; ++counter)
    {
        fileName = [imageArchive nameOfEntry: counter];
        nestedDescription = nil;
		
        if(!([fileName isEqualToString: @""] || [[[fileName lastPathComponent] substringToIndex: 1] isEqualToString: @"."]))
        {
            extension = [[fileName pathExtension] lowercaseString];
            if([[TSSTPage imageExtensions] containsObject: extension])
            {
                nestedDescription = [NSEntityDescription insertNewObjectForEntityForName: @"Image" inManagedObjectContext: [self managedObjectContext]];
				[nestedDescription setValue: fileName forKey: @"imagePath"];
				[nestedDescription setValue: @(counter) forKey: @"index"];
            }
            else if([[[NSUserDefaults standardUserDefaults] valueForKey: TSSTNestedArchives] boolValue] && [[TSSTManagedArchive archiveExtensions] containsObject: extension])
            {
                fileData = [imageArchive contentsOfEntry: counter];
                nestedDescription = [NSEntityDescription insertNewObjectForEntityForName: @"Archive" inManagedObjectContext: [self managedObjectContext]];
                [nestedDescription setValue: fileName forKey: @"name"];
                [nestedDescription setValue: @YES forKey: @"nested"];
				
                collision = 0;
                do {
                    archivePath = [NSString stringWithFormat: @"%i-%@", collision, fileName];
                    archivePath = [NSTemporaryDirectory() stringByAppendingPathComponent: archivePath];
                    ++collision;
                } while ([fileManager fileExistsAtPath: archivePath]);

                [[NSFileManager defaultManager] createDirectoryAtPath: [archivePath stringByDeletingLastPathComponent] 
                                          withIntermediateDirectories: YES 
                                                           attributes: nil 
                                                                error: NULL];
                [[NSFileManager defaultManager] createFileAtPath: archivePath contents: fileData attributes: nil];

                [nestedDescription setValue: archivePath forKey: @"path"];
                [(TSSTManagedArchive *)nestedDescription nestedArchiveContents];
            }
			else if([[TSSTPage textExtensions] containsObject: extension])
			{
				nestedDescription = [NSEntityDescription insertNewObjectForEntityForName: @"Image" inManagedObjectContext: [self managedObjectContext]];
				[nestedDescription setValue: fileName forKey: @"imagePath"];
				[nestedDescription setValue: @(counter) forKey: @"index"];
				[nestedDescription setValue: @YES forKey: @"text"];
			}
            else if([extension isEqualToString: @"pdf"])
            {
                nestedDescription = [NSEntityDescription insertNewObjectForEntityForName: @"PDF" inManagedObjectContext: [self managedObjectContext]];
                archivePath = [NSTemporaryDirectory() stringByAppendingPathComponent: fileName];
                int collision = 0;
                while([fileManager fileExistsAtPath: archivePath])
                {
                    ++collision;
                    fileName = [NSString stringWithFormat: @"%i-%@", collision, fileName];
                    archivePath = [NSTemporaryDirectory() stringByAppendingPathComponent: fileName];
                }
				fileData = [imageArchive contentsOfEntry: counter];
				[fileData writeToFile: archivePath atomically: YES];

                [nestedDescription setValue: archivePath forKey: @"path"];
                [nestedDescription setValue: @YES forKey: @"nested"];
				[(TSSTManagedPDF *)nestedDescription pdfContents];
            }
			
			if(nestedDescription)
			{
				[nestedDescription setValue: self forKey: @"group"];
			}
        }
    }
}


- (BOOL)quicklookCompatible
{	
	NSString * extension = [[[self valueForKey: @"name"] pathExtension] lowercaseString];
	return [[TSSTManagedArchive quicklookExtensions] containsObject: extension];
}


/** Delegates **/

/*  Called when Simple Comic encounters a password protected
 archive.  Brings a password dialog forward. */
-(void)archiveNeedsPassword:(XADArchive *)archive
{
    NSString * password = [self valueForKey: @"password"];
    
    if(password)
    {
        [archive setPassword: password];
        return;
    }
    
    password = [(SimpleComicAppDelegate*)[NSApp delegate] passwordForArchiveWithPath: [self valueForKey: @"path"]];
    [archive setPassword: password];
    
    [self setValue: password forKey: @"password"];
}


@end


@implementation TSSTManagedPDF


- (id)instance
{
    if (!instance)
    {
        instance = [[PDFDocument alloc] initWithData: [NSData dataWithContentsOfFile: [self valueForKey: @"path"]]];
    }
	
    return instance;
}



- (NSData *)dataForPageIndex:(NSInteger)index
{	
    [groupLock lock];
	PDFPage * page = [[self instance] pageAtIndex: index];
    [groupLock unlock];
	
	NSRect bounds = [page boundsForBox: kPDFDisplayBoxMediaBox];
	float dimension = 1400;
	float scale = 1 > (NSHeight(bounds) / NSWidth(bounds)) ? dimension / NSWidth(bounds) :  dimension / NSHeight(bounds);
	bounds.size = scaleSize(bounds.size, scale);
	
	NSImage * pageImage = [[NSImage alloc] initWithSize: bounds.size];
	[pageImage lockFocus];
		[[NSColor whiteColor] set];
		NSRectFill(bounds );
		NSAffineTransform * scaleTransform = [NSAffineTransform transform];
		[scaleTransform scaleBy: scale];
		[scaleTransform concat];
		[page drawWithBox: kPDFDisplayBoxMediaBox];
	[pageImage unlockFocus];
	
	NSData * imageData = [pageImage TIFFRepresentation];
	
    return imageData;
}

- (NSData *)dataForPageName:(NSString *)name
{
    
    return nil;
}


/*  Creates an image managedobject for every "page" in a pdf. */
- (void)pdfContents
{
    NSPDFImageRep * rep = [self instance];
    TSSTPage * imageDescription;
    NSMutableSet * pageSet = [NSMutableSet set];
    NSInteger imageCount = [rep pageCount];
    int pageNumber;
    for (pageNumber = 0; pageNumber < imageCount; ++pageNumber)
    {
        imageDescription = [NSEntityDescription insertNewObjectForEntityForName: @"Image" inManagedObjectContext: [self managedObjectContext]];
        [imageDescription setValue: [NSString stringWithFormat: @"%i", pageNumber + 1] forKey: @"imagePath"];
        [imageDescription setValue: @(pageNumber) forKey: @"index"];
        [pageSet addObject: imageDescription];
    }
	[self setValue: pageSet forKey: @"images"];
}


@end

@implementation SSDManagedSmartFolder{
    
}

- (void) smartFolderContents
{
    TSSTPage *imageDescription;
    NSMutableSet *pageSet = [NSMutableSet set];
  
    NSArray *filenames = nil;
   
    NSString *filepath = [self valueForKey:@"path"];
    BOOL exist = [[NSFileManager new] fileExistsAtPath: filepath];
    if(exist){
        NSLog(@"Path exist");
        
        NSDictionary *dic = [[NSDictionary alloc] initWithContentsOfFile:filepath];
        NSObject * result = [dic objectForKey:@"RawQuery"];
        NSLog(@"%@",result.description);
        
        NSPipe *pipe = [NSPipe pipe];
        NSFileHandle * file = pipe.fileHandleForReading;
        
        
        NSTask *task = [NSTask new];
        task.launchPath = @"/usr/bin/mdfind";
        task.arguments = @[result.description];
        task.standardOutput = pipe;
        
        [task launch];
        
        NSData *data = [file readDataToEndOfFile];
        NSString *resultString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        filenames = [resultString componentsSeparatedByString:@"\n"];
       
    }else{
        NSLog(@"Failed path");
        return;
    }
    

    int pageNumber = 0;
    
    for(NSString *path in filenames){
        if(path){
            NSString * pathExtension = [[path pathExtension] lowercaseString];
            NSLog(@"path: %@  -  extension: %@", path, pathExtension);
            // Handles recognized image files
            if([[TSSTPage imageExtensions] containsObject:pathExtension ]){
                imageDescription = [NSEntityDescription insertNewObjectForEntityForName: @"Image" inManagedObjectContext: [self managedObjectContext]];
                [imageDescription setValue: [NSString stringWithFormat: @"%@", path] forKey: @"imagePath"];
                [imageDescription setValue: @(pageNumber) forKey: @"index"];
                [pageSet addObject: imageDescription];
                pageNumber++;
            }
            else if([[TSSTManagedArchive archiveExtensions] containsObject: pathExtension]){
                NSManagedObject * nestedDescription;
				nestedDescription = [NSEntityDescription insertNewObjectForEntityForName: @"Archive" inManagedObjectContext: [self managedObjectContext]];
				[nestedDescription setValue: path forKey: @"path"];
				[nestedDescription setValue: path forKey: @"name"];
				[(TSSTManagedArchive *)nestedDescription nestedArchiveContents];
                [nestedDescription setValue: self forKey: @"group"];
            }
           
            else if([pathExtension isEqualToString: @"pdf"]){
                NSManagedObject * nestedDescription;
				nestedDescription = [NSEntityDescription insertNewObjectForEntityForName: @"PDF" inManagedObjectContext: [self managedObjectContext]];
				[nestedDescription setValue: path forKey: @"path"];
				[nestedDescription setValue: path forKey: @"name"];
				[(TSSTManagedPDF *)nestedDescription pdfContents];
                [nestedDescription setValue: self forKey: @"group"];
            }
        }
    }
	[self setValue: pageSet forKey: @"images"];
    
}


- (NSData *)dataForPageIndex:(NSInteger)index
{
    NSSet * images = [self valueForKey:@"images"];
    NSString *filepath = nil;
    for(TSSTPage * page in images){
        NSNumber *integer = [page valueForKey:@"index"];
        if([integer isEqualToNumber:@(index)]){
            filepath = [page valueForKey:@"imagePath"];
            break;
        }
        
    }
   
    
#pragma TODO add check to see if file exist?
    if(!filepath){
        return nil;
    }
    
    NSData * data = [NSData dataWithContentsOfFile:  filepath];
    return data;
}

@end