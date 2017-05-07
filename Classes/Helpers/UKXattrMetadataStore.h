//
//  UKXattrMetadataStore.h
//  BubbleBrowser
//	LICENSE: MIT License
//
//  Created by Uli Kusterer on 12.03.06.
//  Copyright 2006 Uli Kusterer. All rights reserved.
//

// -----------------------------------------------------------------------------
//	Headers:
// -----------------------------------------------------------------------------

#import <Cocoa/Cocoa.h>

/*!
 @header UKXattrMetadataStore.h
 
 @discussion
	This is a wrapper around The Mac OS X 10.4 and later xattr API that lets
	you attach arbitrary metadata to a file. Currently it allows querying and
	changing the attributes of a file, as well as retrieving a list of attribute
	names.
	
	It also includes some conveniences for storing/retrieving UTF8 strings,
	and objects as XML property lists in addition to the raw data.
	
	NOTE: keys (i.e. xattr names) are strings of 127 characters or less and
	should be made like bundle identifiers, e.g. @"de.zathras.myattribute".
*/

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4
// -----------------------------------------------------------------------------
//	Class declaration:
// -----------------------------------------------------------------------------

NS_ASSUME_NONNULL_BEGIN

@interface UKXattrMetadataStore : NSObject

/*!
 *	@method		allKeysAtPath:traverseLink:
 *	@param		path
 *				The file to get xattr names from.
 *	@param		travLnk
 *				If <code>YES</code>, follows symlinks.
 *	@return		An \c NSArray of <code>NSString</code>s, or \c nil on failure.
 *	@discussion	Returns an \c NSArray of <code>NSString</code>s containing all xattr names currently set
 *				for the file at the specified path.
 */
+(nullable NSArray<NSString*>*) allKeysAtPath:(NSString*)path traverseLink:(BOOL)travLnk;

#pragma mark Store UTF8 strings:
/*!
 *	@method		setString:forKey:atPath:traverseLink:
 *	@brief		Set the xattr with name \c key to the UTF8 representation of <code>str</code>.
 *	@param		str
 *				The string to set.
 *	@param		key
 *				the key to set \c str to.
 *	@param		path
 *				The file whose xattr you want to set.
 *	@param		travLnk
 *				If <code>YES</code>, follows symlinks.
 *	@discussion	Set the xattr with name key to an XML property list representation of
 *				the specified object (or object graph).
 *	@deprecated	This method throws an Obj-C exception. No other error information is provided, not even if it was successful.
 */
+(void) setString:(NSString*)str forKey:(NSString*)key
		   atPath:(NSString*)path traverseLink:(BOOL)travLnk DEPRECATED_ATTRIBUTE NS_SWIFT_UNAVAILABLE("Use 'setString(_:forKey:atPath:traverseLink:) throws' instead");

/*!
 *	@method		setString:forKey:atPath:traverseLink:error:
 *	@brief		Set the xattr with name \c key to the UTF8 representation of <code>str</code>.
 *	@param		str
 *				The string to set.
 *	@param		key
 *				the key to set \c str to.
 *	@param		path
 *				The file whose xattr you want to set.
 *	@param		travLnk
 *				If <code>YES</code>, follows symlinks.
 *	@param		outError
 *				If the method does not complete successfully, upon return 
 *				contains an \c NSError object that describes the problem.
 *	@return		\c YES on success, \c NO on failure.
 *	@discussion	Set the xattr with name \c key to the UTF8 representation of <code>str</code>.
 */
+(BOOL) setString:(NSString*)str forKey:(NSString*)key
		   atPath:(NSString*)path traverseLink:(BOOL)travLnk error:(NSError**)outError;

/*!
 *	@method		stringForKey:atPath:traverseLink:
 *	@brief		Get the xattr with name \c key as a UTF8 string.
 *	@param		key
 *				the key to set \c str to.
 *	@param		path
 *				The file whose xattr you want to get.
 *	@param		travLnk
 *				If <code>YES</code>, follows symlinks.
 *	@return		an \c NSString on succes, or \c nil on failure.
 *	@discussion	Get the xattr with name \c key as a UTF8 string.
 *	@deprecated	This method has no error handling.
 */
+(nullable NSString*) stringForKey:(NSString*)key atPath:(NSString*)path
					  traverseLink:(BOOL)travLnk DEPRECATED_ATTRIBUTE NS_SWIFT_UNAVAILABLE("Use 'string(forKey:atPath:traverseLink:) throws' instead");

/*!
 *	@method		stringForKey:atPath:traverseLink:error:
 *	@brief		Get the xattr with name \c key as a UTF8 string.
 *	@param		key
 *				the key to set \c str to.
 *	@param		path
 *				The file whose xattr you want to get.
 *	@param		travLnk
 *				If <code>YES</code>, follows symlinks.
 *	@param		error
 *				If the method does not complete successfully, upon return
 *				contains an \c NSError object that describes the problem.
 *	@return		an \c NSString on succes, or \c nil on failure.
 *	@discussion	Get the xattr with name \c key as a UTF-8 string.
 */
+(nullable NSString*) stringForKey:(NSString*)key atPath:(NSString*)path
					  traverseLink:(BOOL)travLnk error:(NSError**)error;

#pragma mark Store raw data:
/*!
 *	@method		setData:forKey:atPath:traverseLink:
 *	@brief		Set the xattr with name \c key to the raw data in <code>data</code>.
 *	@param		data
 *				The data to set.
 *	@param		key
 *				the key to set \c data to.
 *	@param		path
 *				The file whose xattr you want to set.
 *	@param		travLnk
 *				If <code>YES</code>, follows symlinks.
 *	@discussion	Set the xattr with name key to an XML property list representation of
 *				the specified object (or object graph).
 *	@deprecated	This method has no way of indicating success or failure.
 */
+(void) setData:(NSData*)data forKey:(NSString*)key
		 atPath:(NSString*)path traverseLink:(BOOL)travLnk DEPRECATED_ATTRIBUTE NS_SWIFT_UNAVAILABLE("Use 'setData(_:forKey:atPath:traverseLink:) throws' instead");
/*!
 *	@method		setData:forKey:atPath:traverseLink:error:
 *	@brief		Set the xattr with name \c key to the raw data in <code>data</code>.
 *	@param		data
 *				The data to set.
 *	@param		key
 *				the key to set \c data to.
 *	@param		path
 *				The file whose xattr you want to set.
 *	@param		travLnk
 *				If <code>YES</code>, follows symlinks.
 *	@param		error
 *				If the method does not complete successfully, upon return
 *				contains an \c NSError object that describes the problem.
 *	@return		\c YES on success, \c NO on failure.
 *	@discussion	Set the xattr with name \c key to the raw data in <code>data</code>.
 */
+(BOOL) setData:(NSData*)data forKey:(NSString*)key
		 atPath:(NSString*)path traverseLink:(BOOL)travLnk error:(NSError**)error;

/*!
 *	@method		dataForKey:atPath:traverseLink:
 *	@brief		Get the xattr with name \c key as raw data.
 *	@param		key
 *				the key to set \c str to.
 *	@param		path
 *				The file whose xattr you want to get.
 *	@param		travLnk
 *				If <code>YES</code>, follows symlinks.
 *	@return		an \c NSData containing the contents of \c key on succes, or \c nil on failure
 *	@discussion	Get the xattr with name \c key as a UTF8 string
 *	@deprecated	This method throws an Obj-C exception. No other error information is provoded on failure.
 */
+(nullable NSData*) dataForKey:(NSString*)key atPath:(NSString*)path
				  traverseLink:(BOOL)travLnk DEPRECATED_ATTRIBUTE NS_SWIFT_UNAVAILABLE("Use 'data(forKey:atPath:traverseLink:) throws' instead");
/*!
 *	@method		dataForKey:atPath:traverseLink:error:
 *	@brief		Get the xattr with name \c key as raw data.
 *	@param		key
 *				the key to set \c str to.
 *	@param		path
 *				The file whose xattr you want to get.
 *	@param		travLnk
 *				If <code>YES</code>, follows symlinks.
 *	@param		error
 *				If the method does not complete successfully, upon return
 *				contains an \c NSError object that describes the problem.
 *	@return		an \c NSData containing the contents of \c key on succes, or \c nil on failure
 *	@discussion	Get the xattr with name \c key as a UTF8 string
 */
+(nullable NSData*) dataForKey:(NSString*)key atPath:(NSString*)path
				  traverseLink:(BOOL)travLnk error:(NSError**)error;

#pragma mark Store objects: (Only can get/set plist-type objects for now)‚
/*!
 *	@method		setObject:forKey:atPath:traverseLink:
 *	@param		obj
 *				The property list object to set.
 *	@param		key
 *				the key to set \c obj to.
 *	@param		path
 *				The file whose xattr you want to set.
 *	@param		travLnk
 *				If <code>YES</code>, follows symlinks.
 *	@discussion	Set the xattr with name key to an XML property list representation of
 *				the specified object (or object graph).
 *	@deprecated	This method throws an Obj-C exception. No other error information is provided,
 *				not even if it was successful.
 */
+(void) setObject:(id)obj forKey:(NSString*)key atPath:(NSString*)path
	 traverseLink:(BOOL)travLnk DEPRECATED_ATTRIBUTE NS_SWIFT_UNAVAILABLE("Use 'setObject(_:forKey:atPath:traverseLink:) throws' instead");

/*!
 *	@method		setObject:forKey:atPath:traverseLink:error:
 *	@param		obj
 *				The Property List object to set.
 *	@param		key
 *				the key to set \obj to.
 *	@param		path
 *				The file whose xattr you want to set.
 *	@param		travLnk
 *				If <code>YES</code>, follows symlinks.
 *	@param		error
 *				If the method does not complete successfully, upon return
 *				contains an \c NSError object that describes the problem.
 *	@return		\c YES on success, \c NO on failure.
 *	@discussion	Set the xattr with name \c key to an XML property list representation of
 *				the specified object (or object graph).
 */
+(BOOL) setObject:(id)obj forKey:(NSString*)key atPath:(NSString*)path
	 traverseLink:(BOOL)travLnk error:(NSError**)error;

/*!
 *	@method		objectForKey:atPath:traverseLink:error:
 *	@brief		Get the xattr with name \c key as a property list
 *	@param		key
 *				the key to get the Property List object from.
 *	@param		path
 *				The file whose xattr you want to get.
 *	@param		travLnk
 *				If <code>YES</code>, follows symlinks.
 *	@param		outError
 *				If the method does not complete successfully, upon return
 *				contains an \c NSError object that describes the problem.
 *	@return		a Property List object from contents of \c key on succes, or \c nil on failure
 *	@discussion	Get the xattr with name \c key as a property list object (<code>NSString</code>, <code>NSArray</code>, etc...)<br>
 *				The data has to be stored as an XML property list.
 */
+(nullable id) objectForKey:(NSString*)key atPath:(NSString*)path
			   traverseLink:(BOOL)travLnk error:(NSError**)outError;

@end

NS_ASSUME_NONNULL_END

#endif /*MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4*/
