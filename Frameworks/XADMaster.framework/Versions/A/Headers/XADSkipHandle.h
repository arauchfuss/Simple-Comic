#import "CSHandle.h"

typedef struct XADSkipRegion
{
	off_t actual,skip;
} XADSkipRegion;

//static inline XADSkip XADMakeSkip(off_t start,off_t length) { XADSkip skip={start,length}; return skip; }

@interface XADSkipHandle:CSHandle
{
	CSHandle *parent;
	XADSkipRegion *regions;
	int numregions;
}

-(instancetype)initWithHandle:(CSHandle *)handle NS_DESIGNATED_INITIALIZER;
-(instancetype)initAsCopyOf:(XADSkipHandle *)other NS_DESIGNATED_INITIALIZER;
-(void)dealloc;

-(void)addSkipFrom:(off_t)start length:(off_t)length;
-(void)addSkipFrom:(off_t)start to:(off_t)end;
-(off_t)actualOffsetForSkipOffset:(off_t)skipoffset;
-(off_t)skipOffsetForActualOffset:(off_t)actualoffset;

@property (NS_NONATOMIC_IOSONLY, readonly) off_t fileSize;
@property (NS_NONATOMIC_IOSONLY, readonly) off_t offsetInFile;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL atEndOfFile;

-(void)seekToFileOffset:(off_t)offs;
-(void)seekToEndOfFile;
-(int)readAtMost:(int)num toBuffer:(void *)buffer;

@end
