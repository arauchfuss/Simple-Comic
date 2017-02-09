#import "CSStreamHandle.h"
#import "../../Crypto/aes.h"
#import "../../Crypto/hmac_sha1.h"

@interface XADWinZipAESHandle:CSStreamHandle
{
	CSHandle *parent;
	NSData *password;
	int keybytes;
	off_t startoffs;

	aes_encrypt_ctx aes;
	uint8_t counter[16],aesbuffer[16];
	HMAC_SHA1_CTX hmac;
	BOOL hmac_done,hmac_correct;
}

-(id)initWithHandle:(CSHandle *)handle length:(off_t)length password:(NSData *)passdata keyLength:(int)keylength;
-(void)dealloc;

-(void)resetStream;
-(int)streamAtMost:(int)num toBuffer:(void *)buffer;

@end
