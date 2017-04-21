//
//  UKXattrMetadataStore.m
//  BubbleBrowser
//	LICENSE: MIT License
//
//  Created by Uli Kusterer on 12.03.06.
//  Copyright 2006 Uli Kusterer. All rights reserved.
//

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4
// -----------------------------------------------------------------------------
//	Headers:
// -----------------------------------------------------------------------------

#import "UKXattrMetadataStore.h"
#include <sys/xattr.h>


@implementation UKXattrMetadataStore

// -----------------------------------------------------------------------------
//	allKeysAtPath:traverseLink:
//		Return an NSArray of NSStrings containing all xattr names currently set
//		for the file at the specified path.
//		If travLnk == YES, it follows symlinks.
// -----------------------------------------------------------------------------

+(NSArray*) allKeysAtPath: (NSString*)path traverseLink:(BOOL)travLnk
{
	NSMutableArray<NSString*>*	allKeys = [NSMutableArray array];
	size_t dataSize = listxattr( [path fileSystemRepresentation],
								NULL, ULONG_MAX,
								(travLnk ? 0 : XATTR_NOFOLLOW) );
	if( dataSize == ULONG_MAX )
		return nil;	// Empty list.
	NSMutableData*	listBuffer = [NSMutableData dataWithLength: dataSize];
	dataSize = listxattr( [path fileSystemRepresentation],
							[listBuffer mutableBytes], [listBuffer length],
							(travLnk ? 0 : XATTR_NOFOLLOW) );
	NSString *allStrKeys = [[NSString alloc] initWithData:listBuffer encoding:NSUTF8StringEncoding];
	[allKeys setArray:[allStrKeys componentsSeparatedByString:@"\0"]];
	if (allKeys.lastObject.length == 0) {
		[allKeys removeLastObject];
	}
	
	return [allKeys copy];
}


// -----------------------------------------------------------------------------
//	setData:forKey:atPath:traverseLink:
//		Set the xattr with name key to a block of raw binary data.
//		path is the file whose xattr you want to set.
//		If travLnk == YES, it follows symlinks.
// -----------------------------------------------------------------------------

+(void) setData: (NSData*)data forKey: (NSString*)key atPath: (NSString*)path traverseLink:(BOOL)travLnk
{
	[self setData:data forKey:key atPath:path traverseLink:travLnk error:NULL];
}

+(BOOL) setData: (NSData*)data forKey: (NSString*)key atPath: (NSString*)path traverseLink:(BOOL)travLnk error:(NSError**)error
{
	int iErr = setxattr([path fileSystemRepresentation], [key UTF8String],
				[data bytes], [data length],
				0, (travLnk ? 0 : XATTR_NOFOLLOW) );
	if (iErr == -1) {
		if (error) {
			*error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:@{NSFilePathErrorKey: path}];
		}
		return NO;
	}
	return YES;
}
// -----------------------------------------------------------------------------
//	setObject:forKey:atPath:traverseLink:
//		Set the xattr with name key to an XML property list representation of
//		the specified object (or object graph).
//		path is the file whose xattr you want to set.
//		If travLnk == YES, it follows symlinks.
// -----------------------------------------------------------------------------

+(void)	setObject: (id)obj forKey: (NSString*)key atPath: (NSString*)path traverseLink:(BOOL)travLnk
{
	// Serialize our objects into a property list XML string:
	NSString*	errMsg = nil;
	NSData*		plistData = [NSPropertyListSerialization dataFromPropertyList: obj
								format: NSPropertyListXMLFormat_v1_0
								errorDescription: &errMsg];
	if( errMsg )
	{
		[NSException raise: @"UKXattrMetastoreCantSerialize" format: @"%@", errMsg];
	}
	else
		[self setData: plistData forKey: key atPath: path traverseLink: travLnk error: NULL];
}

+(BOOL)	setObject: (id)obj forKey: (NSString*)key atPath: (NSString*)path traverseLink:(BOOL)travLnk error:(NSError**)error
{
	// Serialize our objects into a property list XML string:
	NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:obj format:NSPropertyListXMLFormat_v1_0 options:0 error:error];

	if( !plistData )
	{
		//NSPropertyListSerialization should have filled out the error.
		return NO;
	}
	else
		return [self setData: plistData forKey: key atPath: path traverseLink: travLnk error: error];
}


// -----------------------------------------------------------------------------
//	setString:forKey:atPath:traverseLink:
//		Set the xattr with name key to an XML property list representation of
//		the specified object (or object graph).
//		path is the file whose xattr you want to set.
//		If travLnk == YES, it follows symlinks.
// -----------------------------------------------------------------------------

+(void)	setString: (NSString*)str forKey: (NSString*)key atPath: (NSString*)path traverseLink:(BOOL)travLnk
{
	NSData*		data = [str dataUsingEncoding: NSUTF8StringEncoding];
	
	if( !data )
		[NSException raise: NSCharacterConversionException format: @"Couldn't convert string to UTF8 for xattr storage."];
	
	[[self class] setData: data forKey: key atPath: path traverseLink: travLnk error: nil];
}

+(BOOL)	setString: (NSString*)str forKey: (NSString*)key atPath: (NSString*)path traverseLink:(BOOL)travLnk error:(NSError * _Nullable __autoreleasing * _Nullable)outError
{
	NSData *data = [str dataUsingEncoding: NSUTF8StringEncoding];
	
	if (!data) {
		if (outError) {
			*outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteInapplicableStringEncodingError userInfo:
						 @{NSLocalizedDescriptionKey: @"Couldn't convert string to UTF8 for xattr storage.",
						   NSStringEncodingErrorKey: @(NSUTF8StringEncoding),
						   NSFilePathErrorKey: path}];
		}
		return NO;
	}
	
	return [self setData: data forKey: key atPath: path traverseLink: travLnk error: outError];
}

// -----------------------------------------------------------------------------
//	dataForKey:atPath:traverseLink:
//		Retrieve the xattr with name key as a raw block of data.
//		path is the file whose xattr you want to set.
//		If travLnk == YES, it follows symlinks.
// -----------------------------------------------------------------------------

+(NSData*) dataForKey: (NSString*)key atPath: (NSString*)path traverseLink:(BOOL)travLnk
{
	return [self dataForKey:key atPath:path traverseLink:travLnk error:NULL];
}

+(NSData*) dataForKey: (NSString*)key atPath: (NSString*)path traverseLink:(BOOL)travLnk error:(NSError * _Nullable __autoreleasing * _Nullable)error
{
	size_t		dataSize = getxattr( [path fileSystemRepresentation], [key UTF8String],
									NULL, ULONG_MAX, 0, (travLnk ? 0 : XATTR_NOFOLLOW) );
	if( dataSize == ULONG_MAX ) {
		if (error) {
			*error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:@{NSFilePathErrorKey: path}];
		}
		return nil;
	}
	NSMutableData*	data = [[NSMutableData alloc] initWithLength: dataSize];
	dataSize = getxattr( [path fileSystemRepresentation], [key UTF8String],
				[data mutableBytes], [data length], 0, (travLnk ? 0 : XATTR_NOFOLLOW) );
	
	if (dataSize == -1) {
		if (error) {
			*error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:@{NSFilePathErrorKey: path}];
		}
		return nil;
	}
	
	return [data copy];
}


// -----------------------------------------------------------------------------
//	objectForKey:atPath:traverseLink:
//		Retrieve the xattr with name key, which is an XML property list
//		and unserialize it back into an object or object graph.
//		path is the file whose xattr you want to set.
//		If travLnk == YES, it follows symlinks.
// -----------------------------------------------------------------------------

+(id) objectForKey: (NSString*)key atPath: (NSString*)path traverseLink:(BOOL)travLnk
{
	NSError		*err = nil;
	id obj = [self objectForKey:key atPath:path traverseLink:travLnk error:&err];
	if (!obj) {
		[NSException raise:@"UKXattrMetastoreCantUnserialize" format: @"%@", err];
	}
	
	return obj;
}

+(nullable id) objectForKey: (NSString*)key atPath: (NSString*)path
			   traverseLink: (BOOL)travLnk error: (NSError**)outError
{
	NSData *data = [[self class] dataForKey: key atPath: path traverseLink: travLnk error: outError];
	if (!data) {
		//The dataForKey:... method should have filled out the error variable.
		return nil;
	}
	NSPropertyListFormat	outFormat = NSPropertyListXMLFormat_v1_0;

	id obj = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:&outFormat error:outError];
	if (!obj) {
		//The propertyListWithData:... method should have filled out the error variable.
		return nil;
	}
	
	return obj;
}


// -----------------------------------------------------------------------------
//	stringForKey:atPath:traverseLink:
//		Retrieve the xattr with name key, which is an XML property list
//		and unserialize it back into an object or object graph.
//		path is the file whose xattr you want to set.
//		If travLnk == YES, it follows symlinks.
// -----------------------------------------------------------------------------

+(NSString*) stringForKey: (NSString*)key atPath: (NSString*)path traverseLink:(BOOL)travLnk
{
	NSData *data = [[self class] dataForKey: key atPath: path traverseLink: travLnk error: nil];
	if (!data) {
		return nil;
	}
	
	return [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
}

+(NSString*) stringForKey: (NSString*)key atPath: (NSString*)path traverseLink:(BOOL)travLnk error:(NSError * _Nullable __autoreleasing * _Nullable)error
{
	NSData *data = [[self class] dataForKey: key atPath: path traverseLink: travLnk error: error];
	
	if (!data) {
		//The dataForKey:... method should have filled out the error variable.
		return nil;
	}
	
	NSString *toRet = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
	
	if (!toRet) {
		if (error) {
			*error = [NSError errorWithDomain: NSCocoaErrorDomain
										 code: NSFileReadInapplicableStringEncodingError
									 userInfo:
					  @{NSStringEncodingErrorKey: @(NSUTF8StringEncoding),
						NSFilePathErrorKey: path}];
		}
	}
	
	return toRet;
}


@end

#endif /*MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4*/
