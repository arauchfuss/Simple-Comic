#import "CSBlockStreamHandle.h"

#import "wavpack/wavpack.h"

@interface XADWinZipWavPackHandle:CSBlockStreamHandle
{
	WavpackContext *context;
	BOOL header;
	int headerlength;
	uint8_t *buffer;
}

-(id)initWithHandle:(CSHandle *)handle length:(off_t)length;
-(void)dealloc;

-(void)resetBlockStream;
-(int)produceBlockAtOffset:(off_t)pos;

@end

