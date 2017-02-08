#import "CSByteStreamHandle.h"

@interface XADRAR13CryptHandle:CSByteStreamHandle
{
	NSData *password;

	uint8_t key1,key2,key3;
}

-(id)initWithHandle:(CSHandle *)handle length:(off_t)length password:(NSData *)passdata;
-(void)dealloc;

-(void)resetByteStream;
-(uint8_t)produceByteAtOffset:(off_t)pos;

@end
