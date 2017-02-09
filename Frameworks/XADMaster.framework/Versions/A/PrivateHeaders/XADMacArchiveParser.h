#import "XADArchiveParser.h"
#import "CSStreamHandle.h"

extern NSString *XADIsMacBinaryKey;
extern NSString *XADMightBeMacBinaryKey;
extern NSString *XADDisableMacForkExpansionKey;

@interface XADMacArchiveParser:XADArchiveParser
{
	XADPath *previousname;
	NSMutableArray *dittodirectorystack;

	NSMutableDictionary *queueddittoentry;
	NSData *queueddittodata;

	NSMutableDictionary *cachedentry;
	NSData *cacheddata;
	CSHandle *cachedhandle;
}

+(int)macBinaryVersionForHeader:(NSData *)header;

-(id)init;
-(void)dealloc;

-(void)parse;
-(void)parseWithSeparateMacForks;

-(void)addEntryWithDictionary:(NSMutableDictionary *)dict retainPosition:(BOOL)retainpos;

-(BOOL)parseAppleDoubleWithDictionary:(NSMutableDictionary *)dict
name:(XADPath *)name retainPosition:(BOOL)retainpos;

-(void)setPreviousFilename:(XADPath *)prevname;
-(XADPath *)topOfDittoDirectoryStack;
-(void)pushDittoDirectory:(XADPath *)directory;
-(void)popDittoDirectoryStackUntilCanonicalPrefixFor:(XADPath *)path;

-(void)queueDittoDictionary:(NSMutableDictionary *)dict data:(NSData *)data;
-(void)addQueuedDittoDictionaryAndRetainPosition:(BOOL)retainpos;
-(void)addQueuedDittoDictionaryWithName:(XADPath *)newname
isDirectory:(BOOL)isdir retainPosition:(BOOL)retainpos;

-(BOOL)parseMacBinaryWithDictionary:(NSMutableDictionary *)dict
name:(XADPath *)name retainPosition:(BOOL)retainpos;

-(void)addEntryWithDictionary:(NSMutableDictionary *)dict
retainPosition:(BOOL)retainpos data:(NSData *)data;
-(void)addEntryWithDictionary:(NSMutableDictionary *)dict
retainPosition:(BOOL)retainpos handle:(CSHandle *)handle;

-(CSHandle *)handleForEntryWithDictionary:(NSDictionary *)dict wantChecksum:(BOOL)checksum;

-(NSString *)descriptionOfValueInDictionary:(NSDictionary *)dict key:(NSString *)key;
-(NSString *)descriptionOfKey:(NSString *)key;

-(CSHandle *)rawHandleForEntryWithDictionary:(NSDictionary *)dict wantChecksum:(BOOL)checksum;
-(void)inspectEntryDictionary:(NSMutableDictionary *)dict;

@end
