#import "XADMacArchiveParser.h"

@interface XADZipParser:XADMacArchiveParser
{
	NSMutableDictionary *prevdict;
	NSData *prevname;
}

+(int)requiredHeaderSize;
+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data name:(NSString *)name;
+(NSArray *)volumesForHandle:(CSHandle *)handle firstBytes:(NSData *)data name:(NSString *)name;

-(id)init;
-(void)dealloc;

-(void)parseWithSeparateMacForks;
-(void)parseWithCentralDirectoryAtOffset:(off_t)centraloffs zip64Offset:(off_t)zip64offs;

-(void)parseWithoutCentralDirectory;
-(void)findEndOfStreamMarkerWithZip64Flag:(BOOL)zip64 uncompressedSizePointer:(off_t *)uncompsizeptr
compressedSizePointer:(off_t *)compsizeptr CRCPointer:(uint32_t *)crcptr;
-(void)findNextEntry;

//-(void)findNextZipMarkerStartingAt:(off_t)startpos;
//-(void)findNoSeekMarkerForDictionary:(NSMutableDictionary *)dict;
-(NSDictionary *)parseZipExtraWithLength:(int)length nameData:(NSData *)namedata
uncompressedSizePointer:(off_t *)uncompsizeptr compressedSizePointer:(off_t *)compsizeptr;

-(void)addZipEntryWithSystem:(int)system
extractVersion:(int)extractversion
flags:(int)flags
compressionMethod:(int)compressionmethod
date:(uint32_t)date
crc:(uint32_t)crc
localDate:(uint32_t)localdate
compressedSize:(off_t)compsize
uncompressedSize:(off_t)uncompsize
extendedFileAttributes:(uint32_t)extfileattrib
extraDictionary:(NSDictionary *)extradict
dataOffset:(off_t)dataoffset
nameData:(NSData *)namedata
commentData:(NSData *)commentdata
isLastEntry:(BOOL)islastentry;

-(void)rememberEntry:(NSMutableDictionary *)dict withName:(NSData *)namedata;
-(void)addRemeberedEntryAndForget;

-(CSHandle *)rawHandleForEntryWithDictionary:(NSDictionary *)dict wantChecksum:(BOOL)checksum;
-(CSHandle *)decompressionHandleWithHandle:(CSHandle *)parent method:(int)method flags:(int)flags size:(off_t)size;

-(NSString *)formatName;

@end
