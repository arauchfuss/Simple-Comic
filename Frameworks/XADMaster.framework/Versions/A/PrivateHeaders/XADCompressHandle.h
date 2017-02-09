#import "CSByteStreamHandle.h"
#import "LZW.h"

@interface XADCompressHandle:CSByteStreamHandle
{
	BOOL blockmode;

	LZW *lzw;
	int symbolcounter;

	uint8_t *buffer,*bufferend;
}

-(id)initWithHandle:(CSHandle *)handle flags:(int)compressflags;
-(id)initWithHandle:(CSHandle *)handle length:(off_t)length flags:(int)compressflags;
-(void)dealloc;

-(void)resetByteStream;
-(uint8_t)produceByteAtOffset:(off_t)pos;

@end
