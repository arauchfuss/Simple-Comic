#import "CSBlockStreamHandle.h"

#import "../../Crypto/aes.h"

@interface XADRARAESHandle:CSBlockStreamHandle
{
	CSHandle *parent;
	off_t startoffs;

	aes_decrypt_ctx aes;
	uint8_t iv[16],block[16],buffer[65536];
}

+(NSData *)keyForPassword:(NSString *)password salt:(NSData *)salt brokenHash:(BOOL)brokenhash;

-(id)initWithHandle:(CSHandle *)handle key:(NSData *)keydata;
-(id)initWithHandle:(CSHandle *)handle length:(off_t)length key:(NSData *)keydata;
-(void)dealloc;

-(void)resetBlockStream;
-(int)produceBlockAtOffset:(off_t)pos;

@end
