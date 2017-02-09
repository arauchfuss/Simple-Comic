#import "CSByteStreamHandle.h"

#define XADLZSSMatch -1
#define XADLZSSEnd -2


@interface XADLZSSHandle:CSByteStreamHandle
{
	int (*nextliteral_ptr)(id,SEL,int *,int *,off_t);
	@public
	uint8_t *windowbuffer;
	int windowmask,matchlength,matchoffset;
}

-(id)initWithName:(NSString *)descname windowSize:(int)windowsize;
-(id)initWithName:(NSString *)descname length:(off_t)length windowSize:(int)windowsize;
-(id)initWithHandle:(CSHandle *)handle windowSize:(int)windowsize;
-(id)initWithHandle:(CSHandle *)handle length:(off_t)length windowSize:(int)windowsize;
-(void)dealloc;

-(void)resetByteStream;
-(uint8_t)produceByteAtOffset:(off_t)pos;

-(void)resetLZSSHandle;
-(int)nextLiteralOrOffset:(int *)offset andLength:(int *)length atPosition:(off_t)pos;

@end

static inline uint8_t XADLZSSByteFromWindow(XADLZSSHandle *self,off_t absolutepos)
{
	return self->windowbuffer[absolutepos&self->windowmask];
}
