#import <Foundation/Foundation.h>
#import "XADException.h"
#import "XADString.h"
#import "XADPath.h"
#import "XADRegex.h"
#import "CSHandle.h"
#import "XADSkipHandle.h"
#import "Checksums.h"

extern NSString *XADFileNameKey;
extern NSString *XADFileSizeKey;
extern NSString *XADCompressedSizeKey;
extern NSString *XADLastModificationDateKey;
extern NSString *XADLastAccessDateKey;
extern NSString *XADLastAttributeChangeDateKey;
extern NSString *XADCreationDateKey;
extern NSString *XADFileTypeKey;
extern NSString *XADFileCreatorKey;
extern NSString *XADFinderFlagsKey;
extern NSString *XADFinderInfoKey;
extern NSString *XADPosixPermissionsKey;
extern NSString *XADPosixUserKey;
extern NSString *XADPosixGroupKey;
extern NSString *XADPosixUserNameKey;
extern NSString *XADPosixGroupNameKey;
extern NSString *XADDOSFileAttributesKey;
extern NSString *XADWindowsFileAttributesKey;
extern NSString *XADAmigaProtectionBitsKey;

extern NSString *XADIsEncryptedKey;
extern NSString *XADIsCorruptedKey;
extern NSString *XADIsDirectoryKey;
extern NSString *XADIsResourceForkKey;
extern NSString *XADIsArchiveKey;
extern NSString *XADIsHiddenKey;
extern NSString *XADIsLinkKey;
extern NSString *XADIsHardLinkKey;
extern NSString *XADLinkDestinationKey;
extern NSString *XADIsCharacterDeviceKey;
extern NSString *XADIsBlockDeviceKey;
extern NSString *XADDeviceMajorKey;
extern NSString *XADDeviceMinorKey;
extern NSString *XADIsFIFOKey;

extern NSString *XADCommentKey;
extern NSString *XADDataOffsetKey;
extern NSString *XADDataLengthKey;
extern NSString *XADSkipOffsetKey;
extern NSString *XADSkipLengthKey;
extern NSString *XADCompressionNameKey;

extern NSString *XADIsSolidKey;
extern NSString *XADFirstSolidEntryKey;
extern NSString *XADNextSolidEntryKey;
extern NSString *XADSolidObjectKey;
extern NSString *XADSolidOffsetKey;
extern NSString *XADSolidLengthKey;

// Archive properties only
extern NSString *XADArchiveNameKey;
extern NSString *XADVolumesKey;
extern NSString *XADDiskLabelKey;

@interface XADArchiveParser:NSObject
{
	CSHandle *sourcehandle;
	XADSkipHandle *skiphandle;

	id delegate;
	NSString *password;

	NSMutableDictionary *properties;
	XADStringSource *stringsource;

	id parsersolidobj;
	NSMutableDictionary *firstsoliddict,*prevsoliddict;
	id currsolidobj;
	CSHandle *currsolidhandle;

	BOOL shouldstop;

	NSAutoreleasePool *autopool;
}

+(void)initialize;
+(Class)archiveParserClassForHandle:(CSHandle *)handle firstBytes:(NSData *)header
name:(NSString *)name propertiesToAdd:(NSMutableDictionary *)props;
+(XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle name:(NSString *)name;
+(XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle firstBytes:(NSData *)header name:(NSString *)name;
+(XADArchiveParser *)archiveParserForPath:(NSString *)filename;

-(id)initWithHandle:(CSHandle *)handle name:(NSString *)name;
-(void)dealloc;

-(NSDictionary *)properties;
-(NSString *)name;
-(NSString *)filename;
-(NSArray *)allFilenames;
-(BOOL)isEncrypted;

-(id)delegate;
-(void)setDelegate:(id)newdelegate;

-(NSString *)password;
-(BOOL)hasPassword;
-(void)setPassword:(NSString *)newpassword;

-(XADStringSource *)stringSource;

-(XADString *)linkDestinationForDictionary:(NSDictionary *)dict;
-(NSData *)finderInfoForDictionary:(NSDictionary *)dict;



// Internal functions

+(NSArray *)scanForVolumesWithFilename:(NSString *)filename
regex:(XADRegex *)regex firstFileExtension:(NSString *)firstext;

-(BOOL)shouldKeepParsing;

-(CSHandle *)handle;
-(CSHandle *)handleAtDataOffsetForDictionary:(NSDictionary *)dict;
-(XADSkipHandle *)skipHandle;
-(CSHandle *)zeroLengthHandleWithChecksum:(BOOL)checksum;
-(CSHandle *)subHandleFromSolidStreamForEntryWithDictionary:(NSDictionary *)dict;

-(NSArray *)volumes;
-(off_t)offsetForVolume:(int)disk offset:(off_t)offset;

-(void)setObject:(id)object forPropertyKey:(NSString *)key;
-(void)addPropertiesFromDictionary:(NSDictionary *)dict;
-(void)setIsMacArchive:(BOOL)ismac;

-(void)addEntryWithDictionary:(NSMutableDictionary *)dict;
-(void)addEntryWithDictionary:(NSMutableDictionary *)dict retainPosition:(BOOL)retainpos;
-(void)addEntryWithDictionary:(NSMutableDictionary *)dict cyclePools:(BOOL)cyclepools;
-(void)addEntryWithDictionary:(NSMutableDictionary *)dict retainPosition:(BOOL)retainpos cyclePools:(BOOL)cyclepools;

-(XADString *)XADStringWithString:(NSString *)string;
-(XADString *)XADStringWithData:(NSData *)data;
-(XADString *)XADStringWithData:(NSData *)data encodingName:(NSString *)encoding;
-(XADString *)XADStringWithBytes:(const void *)bytes length:(int)length;
-(XADString *)XADStringWithBytes:(const void *)bytes length:(int)length encodingName:(NSString *)encoding;
-(XADString *)XADStringWithCString:(const char *)cstring;
-(XADString *)XADStringWithCString:(const char *)cstring encodingName:(NSString *)encoding;

-(XADPath *)XADPath;
-(XADPath *)XADPathWithString:(NSString *)string;
-(XADPath *)XADPathWithUnseparatedString:(NSString *)string;
-(XADPath *)XADPathWithData:(NSData *)data separators:(const char *)separators;
-(XADPath *)XADPathWithData:(NSData *)data encodingName:(NSString *)encoding separators:(const char *)separators;
-(XADPath *)XADPathWithBytes:(const void *)bytes length:(int)length separators:(const char *)separators;
-(XADPath *)XADPathWithBytes:(const void *)bytes length:(int)length encodingName:(NSString *)encoding separators:(const char *)separators;
-(XADPath *)XADPathWithCString:(const char *)cstring separators:(const char *)separators;
-(XADPath *)XADPathWithCString:(const char *)cstring encodingName:(NSString *)encoding separators:(const char *)separators;

-(NSData *)encodedPassword;
-(const char *)encodedCStringPassword;


// Subclasses implement these:

+(int)requiredHeaderSize;
+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data
name:(NSString *)name;
+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data
name:(NSString *)name propertiesToAdd:(NSMutableDictionary *)props;
+(NSArray *)volumesForHandle:(CSHandle *)handle firstBytes:(NSData *)data
name:(NSString *)name;

-(void)parse;
-(CSHandle *)handleForEntryWithDictionary:(NSDictionary *)dict wantChecksum:(BOOL)checksum;
-(NSString *)formatName;

-(CSHandle *)handleForSolidStreamWithObject:(id)obj wantChecksum:(BOOL)checksum;

@end

@interface NSObject (XADArchiveParserDelegate)

-(void)archiveParser:(XADArchiveParser *)parser foundEntryWithDictionary:(NSDictionary *)dict;
-(BOOL)archiveParsingShouldStop:(XADArchiveParser *)parser;
-(void)archiveParserNeedsPassword:(XADArchiveParser *)parser;

@end

NSMutableArray *XADSortVolumes(NSMutableArray *volumes,NSString *firstfileextension);
