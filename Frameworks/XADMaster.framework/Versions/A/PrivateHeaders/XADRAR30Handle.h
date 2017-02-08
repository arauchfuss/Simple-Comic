#import "CSBlockStreamHandle.h"
#import "XADRARParser.h"
#import "LZSS.h"
#import "XADPrefixCode.h"
#import "../Other/PPMd/PPMd/VariantH.h"
#import "../Other/PPMd/PPMd/SubAllocatorVariantH.h"
#import "XADRARVirtualMachine.h"

@interface XADRAR30Handle:CSBlockStreamHandle 
{
	XADRARParser *parser;

	NSArray *files;
	int file;
	off_t lastend;
	BOOL startnewfile,startnewtable;

	LZSS lzss;

	XADPrefixCode *maincode,*offsetcode,*lowoffsetcode,*lengthcode;

	int lastoffset,lastlength;
	int oldoffset[4];
	int lastlowoffset,numlowoffsetrepeats;

	BOOL ppmblock;
	PPMdModelVariantH ppmd;
	PPMdSubAllocatorVariantH *alloc;
	int ppmescape;

	XADRARVirtualMachine *vm;
	NSMutableArray *filtercode,*stack;
	off_t filterstart;
	int lastfilternum;
	int oldfilterlength[1024],usagecount[1024];
	off_t currfilestartpos;

	int lengthtable[299+60+17+28];
}

-(id)initWithRARParser:(XADRARParser *)parent files:(NSArray *)filearray;
-(void)dealloc;

-(void)resetBlockStream;
-(int)produceBlockAtOffset:(off_t)pos;
-(off_t)expandToPosition:(off_t)end;
-(void)allocAndParseCodes;

-(void)readFilterFromInput;
-(void)readFilterFromPPMd;
-(void)parseFilter:(const uint8_t *)bytes length:(int)length flags:(int)flags;

@end
