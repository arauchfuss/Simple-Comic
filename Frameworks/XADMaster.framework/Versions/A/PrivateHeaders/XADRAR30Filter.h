#import "XADRARParser.h"
#import "XADRARVirtualMachine.h"

@interface XADRAR30Filter:NSObject
{
	XADRARProgramInvocation *invocation;
	off_t blockstartpos;
	int blocklength;

	uint32_t filteredblockaddress,filteredblocklength;
}

+(XADRAR30Filter *)filterForProgramInvocation:(XADRARProgramInvocation *)program
startPosition:(off_t)startpos length:(int)length;

-(id)initWithProgramInvocation:(XADRARProgramInvocation *)program
startPosition:(off_t)startpos length:(int)length;
-(void)dealloc;

-(off_t)startPosition;
-(int)length;

-(uint32_t)filteredBlockAddress;
-(uint32_t)filteredBlockLength;

-(void)executeOnVirtualMachine:(XADRARVirtualMachine *)vm atPosition:(off_t)pos;

@end

@interface XADRAR30DeltaFilter:XADRAR30Filter {}
-(void)executeOnVirtualMachine:(XADRARVirtualMachine *)vm atPosition:(off_t)pos;
@end

@interface XADRAR30AudioFilter:XADRAR30Filter {}
-(void)executeOnVirtualMachine:(XADRARVirtualMachine *)vm atPosition:(off_t)pos;
@end

@interface XADRAR30E8Filter:XADRAR30Filter {}
-(void)executeOnVirtualMachine:(XADRARVirtualMachine *)vm atPosition:(off_t)pos;
@end

@interface XADRAR30E8E9Filter:XADRAR30Filter {}
-(void)executeOnVirtualMachine:(XADRARVirtualMachine *)vm atPosition:(off_t)pos;
@end
