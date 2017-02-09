#import "CSBlockStreamHandle.h"

#import "aes.h"

@interface XAD7ZipAESHandle:CSBlockStreamHandle
{
	CSHandle *parent;
	off_t startoffs;

	aes_decrypt_ctx aes;
	uint8_t iv[16],block[16],buffer[65536];
}

+(int)logRoundsForPropertyData:(NSData *)propertydata;
+(NSData *)saltForPropertyData:(NSData *)propertydata;
+(NSData *)IVForPropertyData:(NSData *)propertydata;
+(NSData *)keyForPassword:(NSString *)password salt:(NSData *)salt logRounds:(int)logrounds;

-(id)initWithHandle:(CSHandle *)handle length:(off_t)length key:(NSData *)keydata IV:(NSData *)ivdata;
-(void)dealloc;

-(void)resetBlockStream;
-(int)produceBlockAtOffset:(off_t)pos;

@end
