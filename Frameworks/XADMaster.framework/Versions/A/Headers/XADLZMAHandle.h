#import "CSStreamHandle.h"

#if !__LP64__
#define _LZMA_UINT32_IS_ULONG
#endif

#import "lzma/LzmaDec.h"

@interface XADLZMAHandle:CSStreamHandle
{
	CSHandle *parent;
	off_t startoffs;

	CLzmaDec lzma;

	uint8_t inbuffer[16*1024];
	int bufbytes,bufoffs;
}

-(id)initWithHandle:(CSHandle *)handle propertyData:(NSData *)propertydata;
-(id)initWithHandle:(CSHandle *)handle length:(off_t)length propertyData:(NSData *)propertydata;
-(void)dealloc;

-(void)resetStream;
-(int)streamAtMost:(int)num toBuffer:(void *)buffer;

@end
