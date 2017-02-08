#import "CSBlockStreamHandle.h"

@interface XADRAR20CryptHandle:CSBlockStreamHandle
{
	CSHandle *parent;
	off_t startoffs;
	NSData *password;

	uint8_t outblock[16];
    uint32_t key[4];
	uint8_t table[256];
}

-(id)initWithHandle:(CSHandle *)handle length:(off_t)length password:(NSData *)passdata;
-(void)dealloc;

-(void)resetBlockStream;
-(void)calculateKey;
-(int)produceBlockAtOffset:(off_t)pos;

@end
