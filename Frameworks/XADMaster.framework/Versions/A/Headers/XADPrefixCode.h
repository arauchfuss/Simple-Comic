#import "CSInputBuffer.h"

extern NSString *XADInvalidPrefixCodeException;

typedef struct XADCodeTableEntry XADCodeTableEntry;

@interface XADPrefixCode:NSObject
{
	int (*tree)[2];
	int numentries;
	BOOL isstatic;

	int currnode;
	NSMutableArray *stack;

	XADCodeTableEntry *tables[9];
}

+(XADPrefixCode *)prefixCode;
+(XADPrefixCode *)prefixCodeWithLengths:(const int *)lengths numberOfSymbols:(int)numsymbols
maximumLength:(int)maxlength shortestCodeIsZeros:(BOOL)zeros;

-(id)init;
-(id)initWithStaticTable:(int (*)[2])statictable;
-(id)initWithLengths:(const int *)lengths numberOfSymbols:(int)numsymbols
maximumLength:(int)maxlength shortestCodeIsZeros:(BOOL)zeros;
-(void)dealloc;

-(void)addValue:(int)value forCodeWithHighBitFirst:(uint32_t)code length:(int)length;
-(void)addValue:(int)value forCodeWithHighBitFirst:(uint32_t)code length:(int)length repeatAt:(int)repeatpos;
-(void)addValue:(int)value forCodeWithLowBitFirst:(uint32_t)code length:(int)length;
-(void)addValue:(int)value forCodeWithLowBitFirst:(uint32_t)code length:(int)length repeatAt:(int)repeatpos;

-(void)startBuildingTree;
-(void)startZeroBranch;
-(void)startOneBranch;
-(void)finishBranches;
-(void)makeLeafWithValue:(int)value;
-(void)_pushNode;
-(void)_popNode;

@end

int CSInputNextSymbolUsingCode(CSInputBuffer *buf,XADPrefixCode *code);
int CSInputNextSymbolUsingCodeLE(CSInputBuffer *buf,XADPrefixCode *code);
