#import "CSHandle.h"

@interface XADXORHandle:CSHandle
{
	CSHandle *parent;
	NSData *password;
	const uint8_t *passwordbytes;
	int passwordlength;
}

-(id)initWithHandle:(CSHandle *)handle password:(NSData *)passdata;
-(id)initAsCopyOf:(XADXORHandle *)other;
-(void)dealloc;

-(off_t)fileSize;
-(off_t)offsetInFile;
-(BOOL)atEndOfFile;
-(void)seekToFileOffset:(off_t)offs;
-(void)seekToEndOfFile;
-(int)readAtMost:(int)num toBuffer:(void *)buffer;

@end
