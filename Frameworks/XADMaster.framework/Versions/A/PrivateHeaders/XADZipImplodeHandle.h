#import "XADFastLZSSHandle.h"
#import "XADPrefixCode.h"

@interface XADZipImplodeHandle:XADFastLZSSHandle
{
	XADPrefixCode *literalcode,*lengthcode,*offsetcode;
	int offsetbits;
	BOOL literals;
}

-(id)initWithHandle:(CSHandle *)handle length:(off_t)length
largeDictionary:(BOOL)largedict hasLiterals:(BOOL)hasliterals;
-(void)dealloc;

-(void)resetLZSSHandle;
-(XADPrefixCode *)allocAndParseCodeOfSize:(int)size;
//-(int)nextLiteralOrOffset:(int *)offset andLength:(int *)length atPosition:(off_t)pos;
-(void)expandFromPosition:(off_t)pos;

@end
