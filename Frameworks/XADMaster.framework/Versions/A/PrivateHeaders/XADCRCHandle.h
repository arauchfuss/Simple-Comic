#import "CSStreamHandle.h"
#import "Checksums.h"
#import "Progress.h"
#import "CRC.h"

@interface XADCRCHandle:CSStreamHandle
{
	CSHandle *parent;
	uint32_t crc,initcrc,compcrc;
	const uint32_t *table;
}

+(XADCRCHandle *)IEEECRC32HandleWithHandle:(CSHandle *)handle
correctCRC:(uint32_t)correctcrc conditioned:(BOOL)conditioned;
+(XADCRCHandle *)IEEECRC32HandleWithHandle:(CSHandle *)handle length:(off_t)length
correctCRC:(uint32_t)correctcrc conditioned:(BOOL)conditioned;
+(XADCRCHandle *)IBMCRC16HandleWithHandle:(CSHandle *)handle length:(off_t)length
correctCRC:(uint32_t)correctcrc conditioned:(BOOL)conditioned;
+(XADCRCHandle *)CCITTCRC16HandleWithHandle:(CSHandle *)handle length:(off_t)length
correctCRC:(uint32_t)correctcrc conditioned:(BOOL)conditioned;

-(id)initWithHandle:(CSHandle *)handle length:(off_t)length initialCRC:(uint32_t)initialcrc
correctCRC:(uint32_t)correctcrc CRCTable:(const uint32_t *)crctable;
-(void)dealloc;

-(void)resetStream;
-(int)streamAtMost:(int)num toBuffer:(void *)buffer;

-(BOOL)hasChecksum;
-(BOOL)isChecksumCorrect;

@end


