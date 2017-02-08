#import "CSByteStreamHandle.h"

@interface XADDeltaHandle:CSByteStreamHandle
{
	uint8_t deltabuffer[256];
	int distance;
}

-(id)initWithHandle:(CSHandle *)handle;
-(id)initWithHandle:(CSHandle *)handle length:(off_t)length;
-(id)initWithHandle:(CSHandle *)handle deltaDistance:(int)deltadistance;
-(id)initWithHandle:(CSHandle *)handle length:(off_t)length deltaDistance:(int)deltadistance;
-(id)initWithHandle:(CSHandle *)handle propertyData:(NSData *)propertydata;
-(id)initWithHandle:(CSHandle *)handle length:(off_t)length propertyData:(NSData *)propertydata;

-(void)resetByteStream;
-(uint8_t)produceByteAtOffset:(off_t)pos;

@end
