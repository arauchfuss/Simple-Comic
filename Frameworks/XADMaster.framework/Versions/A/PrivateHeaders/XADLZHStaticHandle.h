#import "XADLZSSHandle.h"
#import "XADPrefixCode.h"

@interface XADLZHStaticHandle:XADLZSSHandle
{
	XADPrefixCode *literalcode,*distancecode;
	int blocksize,blockpos;
	int windowbits;
}

-(id)initWithHandle:(CSHandle *)handle length:(off_t)length windowBits:(int)bits;
-(void)dealloc;

-(void)resetLZSSHandle;
-(int)nextLiteralOrOffset:(int *)offset andLength:(int *)length atPosition:(off_t)pos;

-(XADPrefixCode *)allocAndParseCodeOfWidth:(int)bits specialIndex:(int)specialindex;
-(XADPrefixCode *)allocAndParseLiteralCode;

@end
