#import "XADMacArchiveParser.h"

@interface XAD7ZipParser:XADMacArchiveParser
{
	off_t startoffset;

	NSDictionary *mainstreams;

	NSDictionary *currfolder;
	CSHandle *currfolderhandle;
}

+(int)requiredHeaderSize;
+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data name:(NSString *)name;
+(NSArray *)volumesForHandle:(CSHandle *)handle firstBytes:(NSData *)data name:(NSString *)name;

-(id)init;
-(void)dealloc;

-(void)parseWithSeparateMacForks;

-(NSArray *)parseFilesForHandle:(CSHandle *)handle;

-(void)parseBitVectorForHandle:(CSHandle *)handle array:(NSArray *)array key:(NSString *)key;
-(NSIndexSet *)parseDefintionVectorForHandle:(CSHandle *)handle numberOfElements:(int)num;
-(void)parseDatesForHandle:(CSHandle *)handle array:(NSMutableArray *)array key:(NSString *)key;
-(void)parseCRCsForHandle:(CSHandle *)handle array:(NSMutableArray *)array;
-(void)parseNamesForHandle:(CSHandle *)handle array:(NSMutableArray *)array;
-(void)parseAttributesForHandle:(CSHandle *)handle array:(NSMutableArray *)array;

-(NSDictionary *)parseStreamsForHandle:(CSHandle *)handle;
-(NSArray *)parsePackedStreamsForHandle:(CSHandle *)handle;
-(NSArray *)parseFoldersForHandle:(CSHandle *)handle packedStreams:(NSArray *)packedstreams;
-(void)parseFolderForHandle:(CSHandle *)handle dictionary:(NSMutableDictionary *)dictionary
packedStreams:(NSArray *)packedstreams packedStreamIndex:(int *)packedstreamindex;
-(void)parseSubStreamsInfoForHandle:(CSHandle *)handle folders:(NSArray *)folders;
-(void)setupDefaultSubStreamsForFolders:(NSArray *)folders;
-(NSArray *)collectAllSubStreamsFromFolders:(NSArray *)folders;

-(CSHandle *)rawHandleForEntryWithDictionary:(NSDictionary *)dict wantChecksum:(BOOL)checksum;
-(CSHandle *)handleForSolidStreamWithObject:(id)obj wantChecksum:(BOOL)checksum;
-(CSHandle *)handleForStreams:(NSDictionary *)streams folderIndex:(int)folderindex;
-(CSHandle *)outHandleForFolder:(NSDictionary *)folder index:(int)index;
-(CSHandle *)inHandleForFolder:(NSDictionary *)folder coder:(NSDictionary *)coder index:(int)index;
-(CSHandle *)inHandleForFolder:(NSDictionary *)folder index:(int)index;

-(int)IDForCoder:(NSDictionary *)coder;
-(off_t)compressedSizeForFolder:(NSDictionary *)folder;
-(off_t)uncompressedSizeForFolder:(NSDictionary *)folder;
-(NSString *)compressorNameForFolder:(NSDictionary *)folder;
-(NSString *)compressorNameForFolder:(NSDictionary *)folder index:(int)index;
-(NSString *)compressorNameForCoder:(NSDictionary *)coder;
-(BOOL)isFolderEncrypted:(NSDictionary *)folder;
-(BOOL)isFolderEncrypted:(NSDictionary *)folder index:(int)index;

-(NSString *)formatName;

@end

@interface XAD7ZipSFXParser:XAD7ZipParser
{
}

+(int)requiredHeaderSize;
+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data
name:(NSString *)name propertiesToAdd:(NSMutableDictionary *)props;

-(void)parse;
-(NSString *)formatName;

@end
