#import "XADFastLZSSHandle.h"
#import "XADRARParser.h"
#import "XADPrefixCode.h"

@interface XADRAR15Handle:XADFastLZSSHandle
{
	XADRARParser *parser;

	NSArray *files;
	int file;
	off_t endpos;

	XADPrefixCode *lengthcode1,*lengthcode2;
	XADPrefixCode *huffmancode0,*huffmancode1,*huffmancode2,*huffmancode3,*huffmancode4;
	XADPrefixCode *shortmatchcode0,*shortmatchcode1,*shortmatchcode2,*shortmatchcode3;

	BOOL storedblock;

	unsigned int flags,flagbits;
	unsigned int literalweight,matchweight;
	unsigned int numrepeatedliterals,numrepeatedlastmatches;
	unsigned int runningaverageliteral,runningaverageselector;
	unsigned int runningaveragelength,runningaverageoffset,runningaveragebelowmaximum;
	unsigned int maximumoffset;
	BOOL bugfixflag;

	int lastoffset,lastlength;
	int oldoffset[4],oldoffsetindex;

	int flagtable[256],flagreverse[256];
	int literaltable[256],literalreverse[256];
	int offsettable[256],offsetreverse[256];
	int shortoffsettable[256];
}

-(id)initWithRARParser:(XADRARParser *)parent files:(NSArray *)filearray;
-(void)dealloc;

-(void)resetLZSSHandle;
-(void)startNextFile;
-(void)expandFromPosition:(off_t)pos;

@end
