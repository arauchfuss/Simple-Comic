#import "XADLZSSHandle.h"
#import "XADPrefixCode.h"

#define XADNormalDeflateVariant 0
#define XADDeflate64DeflateVariant 1
#define XADStuffItXDeflateVariant 2
#define XADNSISDeflateVariant 3

@interface XADDeflateHandle:XADLZSSHandle
{
	int variant;

	XADPrefixCode *literalcode,*distancecode;
	XADPrefixCode *fixedliteralcode,*fixeddistancecode;
	BOOL storedblock,lastblock;
	int storedcount;

	int order[19];
}

-(id)initWithHandle:(CSHandle *)handle length:(off_t)length;
-(id)initWithHandle:(CSHandle *)handle length:(off_t)length variant:(int)deflatevariant;
-(void)dealloc;

-(void)setMetaTableOrder:(const int *)order;

-(void)resetLZSSHandle;
-(int)nextLiteralOrOffset:(int *)offset andLength:(int *)length atPosition:(off_t)pos;

-(void)readBlockHeader;
-(XADPrefixCode *)allocAndParseMetaCodeOfSize:(int)size;
-(XADPrefixCode *)fixedLiteralCode;
-(XADPrefixCode *)fixedDistanceCode;

@end
