#import "XADArchiveParser.h"
#import "CSInputBuffer.h"

typedef struct RARBlock
{
	int crc,type,flags;
	int headersize;
	off_t datasize;
	off_t start,datastart;
	CSHandle *fh;
} RARBlock;

typedef struct RARFileHeader
{
	off_t size;
	int os;
	uint32_t crc,dostime;
	int version,method,namelength;
	uint32_t attrs;
	NSData *namedata,*salt;
} RARFileHeader;

@interface XADRARParser:XADArchiveParser
{
	int archiveflags,encryptversion;

//	NSMutableDictionary *lastcompressed;
	NSMutableDictionary *keys;
}

+(int)requiredHeaderSize;
+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data name:(NSString *)name;
+(NSArray *)volumesForHandle:(CSHandle *)handle firstBytes:(NSData *)data name:(NSString *)name;

-(void)setPassword:(NSString *)newpassword;

-(void)parse;

-(RARFileHeader)readFileHeaderWithBlock:(RARBlock *)block;
-(NSData *)readComment;

-(RARBlock)readBlockHeader;
-(void)skipBlock:(RARBlock)block;

-(void)addEntryWithBlock:(const RARBlock *)block header:(const RARFileHeader *)header
compressedSize:(off_t)compsize files:(NSArray *)files solidOffset:(off_t)solidoffs
isCorrupted:(BOOL)iscorrupted;
-(XADPath *)parseNameData:(NSData *)data flags:(int)flags;

-(CSHandle *)handleForEntryWithDictionary:(NSDictionary *)dict wantChecksum:(BOOL)checksum;
-(CSHandle *)handleForSolidStreamWithObject:(id)obj wantChecksum:(BOOL)checksum;

-(CSInputBuffer *)inputBufferForFileWithIndex:(int)file files:(NSArray *)files;
-(CSHandle *)inputHandleForFileWithIndex:(int)file files:(NSArray *)files;
-(CSHandle *)inputHandleWithParts:(NSArray *)parts encrypted:(BOOL)encrypted
cryptoVersion:(int)version salt:(NSData *)salt;
-(NSData *)keyForSalt:(NSData *)salt;

-(off_t)outputLengthOfFileWithIndex:(int)file files:(NSArray *)files;

-(NSString *)formatName;

@end


@interface XADEmbeddedRARParser:XADRARParser
{
}

+(int)requiredHeaderSize;
+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data
name:(NSString *)name propertiesToAdd:(NSMutableDictionary *)props;

-(void)parse;
-(NSString *)formatName;

@end
