#import "CSStreamHandle.h"

#if !__LP64__
#define _LZMA_UINT32_IS_ULONG
#endif

#define Byte LzmaByte
#define UInt16 LzmaUInt16
#define UInt32 LzmaUInt32
#define UInt64 LzmaUInt64
#import "LzmaDec.h"
#undef Byte
#undef UInt32
#undef UInt16
#undef UInt64

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
