#import "XADLZSSHandle.h"

@interface XADLArcLZSHandle:XADLZSSHandle
{
}

-(id)initWithHandle:(CSHandle *)handle length:(off_t)length;
-(int)nextLiteralOrOffset:(int *)offset andLength:(int *)length atPosition:(off_t)pos;

@end

@interface XADLArcLZ5Handle:XADLZSSHandle
{
	int flags,flagbit;
}

-(id)initWithHandle:(CSHandle *)handle length:(off_t)length;
-(void)resetLZSSHandle;
-(int)nextLiteralOrOffset:(int *)offset andLength:(int *)length atPosition:(off_t)pos;

@end
