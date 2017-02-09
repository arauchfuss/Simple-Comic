#import "CSByteStreamHandle.h"

@interface XAD7ZipBCJ2Handle:CSByteStreamHandle
{
	CSHandle *calls,*jumps,*ranges;
	off_t callstart,jumpstart,rangestart;

	uint16_t probabilities[258];
	uint32_t range,code;

	int prevbyte;
	uint32_t val;
	int valbyte;
}

-(id)initWithHandle:(CSHandle *)handle callHandle:(CSHandle *)callhandle
jumpHandle:(CSHandle *)jumphandle rangeHandle:(CSHandle *)rangehandle length:(off_t)length;
-(void)dealloc;
-(void)resetByteStream;
-(uint8_t)produceByteAtOffset:(off_t)pos;

@end
