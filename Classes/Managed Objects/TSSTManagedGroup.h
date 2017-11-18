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

  TSSTManagedGroup.h
*/

#import <Cocoa/Cocoa.h>

@class TSSTPage;

NS_ASSUME_NONNULL_BEGIN

@interface TSSTManagedGroup : NSManagedObject
{
    id instance;
    NSLock * groupLock;
}

@property (readonly, strong) id instance;

@property (copy) NSString *path;
@property (copy) NSURL *fileURL;

- (nullable NSData *)dataForPageIndex:(NSInteger)index;
@property (readonly, strong, nullable) NSManagedObject *topLevelGroup;
@property (readonly, copy) NSSet<TSSTPage*> *nestedImages;

/**
 Goes through various files like pdfs, images, text files
 from the path folder and it's subfolders and add these
 to the Core Data for the managedObjectContext
 with the info needed to deal with the files.
 */
- (void)nestedFolderContents;

@end

@interface TSSTManagedArchive : TSSTManagedGroup

//! An \c NSArray with archive file extensions which the software supports.
@property (class, readonly, copy) NSArray<NSString*> *archiveExtensions;
//! An \c NSArray with archive UTIs which the software supports.
@property (class, readonly, copy) NSArray<NSString*> *archiveTypes;
//! An \c NSArray with file extensions for which software support QuickLook for.
@property (class, readonly, copy) NSArray<NSString*> *quicklookExtensions;
/**  Recurses through archives looking for archives and images */
- (void)nestedArchiveContents;
@property (readonly) BOOL quicklookCompatible;

@end

@interface TSSTManagedPDF : TSSTManagedGroup

/**  Parses PDFs into something Simple Comic can use.
 *  Creates an image \c NSManagedObject for every "page" in a pdf. */
- (void)pdfContents;

@end

NS_ASSUME_NONNULL_END

#import "TSSTManagedGroup+CoreDataProperties.h"
