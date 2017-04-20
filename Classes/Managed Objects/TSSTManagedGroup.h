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

- (nullable NSData *)dataForPageIndex:(NSInteger)index;
@property (readonly, strong, nullable) NSManagedObject *topLevelGroup;
@property (readonly, copy) NSSet<TSSTPage*> *nestedImages;

- (void)nestedFolderContents;

@end

@interface TSSTManagedArchive : TSSTManagedGroup

+ (NSArray<NSString*> *)archiveExtensions;
+ (NSArray<NSString*> *)quicklookExtensions;
#if __has_feature(objc_class_property)
@property (class, readonly, copy) NSArray<NSString*> *archiveExtensions;
@property (class, readonly, copy) NSArray<NSString*> *quicklookExtensions;
#endif
/**  Recurses through archives looking for archives and images */
- (void)nestedArchiveContents;
@property (readonly) BOOL quicklookCompatible;

@end

@interface TSSTManagedPDF : TSSTManagedGroup

/**  Parses PDFs into something Simple Comic can use */
- (void)pdfContents;

@end

NS_ASSUME_NONNULL_END

#import "TSSTManagedGroup+CoreDataProperties.h"
