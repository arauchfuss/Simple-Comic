#import <Foundation/Foundation.h>

#import "XADArchiveParser.h"

#define XADIgnoredForkStyle 0
#define XADMacOSXForkStyle 1
#define XADHiddenAppleDoubleForkStyle 2
#define XADVisibleAppleDoubleForkStyle 3

#ifdef __APPLE__
#define XADDefaultForkStyle XADMacOSXForkStyle
#else
#define XADDefaultForkStyle XADVisibleAppleDoubleForkStyle
#endif

@interface XADUnarchiver:NSObject
{
	XADArchiveParser *parser;
	NSString *destination;
	int forkstyle;
	BOOL preservepermissions;
	double updateinterval;

	id delegate;

	NSMutableArray *deferreddirectories;
}

+(XADUnarchiver *)unarchiverForArchiveParser:(XADArchiveParser *)archiveparser;
+(XADUnarchiver *)unarchiverForPath:(NSString *)path;

-(id)initWithArchiveParser:(XADArchiveParser *)archiveparser;
-(void)dealloc;

-(XADArchiveParser *)archiveParser;

-(id)delegate;
-(void)setDelegate:(id)newdelegate;

//-(NSString *)password;
//-(void)setPassword:(NSString *)password;

//-(NSStringEncoding)encoding;
//-(void)setEncoding:(NSStringEncoding)encoding;

-(NSString *)destination;
-(void)setDestination:(NSString *)destpath;

-(int)macResourceForkStyle;
-(void)setMacResourceForkStyle:(int)style;

-(BOOL)preservesPermissions;
-(void)setPreserevesPermissions:(BOOL)preserveflag;

-(double)updateInterval;
-(void)setUpdateInterval:(double)interval;

-(XADError)parseAndUnarchive;

-(XADError)extractEntryWithDictionary:(NSDictionary *)dict;
-(XADError)extractEntryWithDictionary:(NSDictionary *)dict forceDirectories:(BOOL)force;
-(XADError)extractEntryWithDictionary:(NSDictionary *)dict as:(NSString *)path;
-(XADError)extractEntryWithDictionary:(NSDictionary *)dict as:(NSString *)path forceDirectories:(BOOL)force;
-(XADError)finishExtractions;

-(XADError)_extractFileEntryWithDictionary:(NSDictionary *)dict as:(NSString *)destpath;
-(XADError)_extractResourceForkEntryWithDictionary:(NSDictionary *)dict asAppleDoubleFile:(NSString *)destpath;
-(XADError)_extractDirectoryEntryWithDictionary:(NSDictionary *)dict as:(NSString *)destpath;
-(XADError)_extractLinkEntryWithDictionary:(NSDictionary *)dict as:(NSString *)destpath;
-(XADError)_extractArchiveEntryWithDictionary:(NSDictionary *)dict to:(NSString *)destpath name:(NSString *)filename;
-(XADError)_extractEntryWithDictionary:(NSDictionary *)dict toHandle:(CSHandle *)fh;

-(XADError)_updateFileAttributesAtPath:(NSString *)path forEntryWithDictionary:(NSDictionary *)dict
deferDirectories:(BOOL)defer;
-(XADError)_ensureDirectoryExists:(NSString *)path;

@end


@interface XADUnarchiver (PlatformSpecific)

-(XADError)_extractResourceForkEntryWithDictionary:(NSDictionary *)dict asPlatformSpecificForkForFile:(NSString *)destpath;
-(XADError)_createPlatformSpecificLinkToPath:(NSString *)link from:(NSString *)path;
-(XADError)_updatePlatformSpecificFileAttributesAtPath:(NSString *)path forEntryWithDictionary:(NSDictionary *)dict;

@end



@interface NSObject (XADUnarchiverDelegate)

-(void)unarchiverNeedsPassword:(XADUnarchiver *)unarchiver;

-(NSString *)unarchiver:(XADUnarchiver *)unarchiver pathForExtractingEntryWithDictionary:(NSDictionary *)dict;
-(BOOL)unarchiver:(XADUnarchiver *)unarchiver shouldExtractEntryWithDictionary:(NSDictionary *)dict to:(NSString *)path;
-(void)unarchiver:(XADUnarchiver *)unarchiver willExtractEntryWithDictionary:(NSDictionary *)dict to:(NSString *)path;
-(void)unarchiver:(XADUnarchiver *)unarchiver didExtractEntryWithDictionary:(NSDictionary *)dict to:(NSString *)path error:(XADError)error;

-(BOOL)unarchiver:(XADUnarchiver *)unarchiver shouldCreateDirectory:(NSString *)directory;

-(BOOL)unarchiver:(XADUnarchiver *)unarchiver shouldExtractArchiveEntryWithDictionary:(NSDictionary *)dict to:(NSString *)path;
-(void)unarchiver:(XADUnarchiver *)unarchiver willExtractArchiveEntryWithDictionary:(NSDictionary *)dict withUnarchiver:(XADUnarchiver *)subunarchiver to:(NSString *)path;
-(void)unarchiver:(XADUnarchiver *)unarchiver didExtractArchiveEntryWithDictionary:(NSDictionary *)dict withUnarchiver:(XADUnarchiver *)subunarchiver to:(NSString *)path error:(XADError)error;

-(NSString *)unarchiver:(XADUnarchiver *)unarchiver linkDestinationForEntryWithDictionary:(NSDictionary *)dict from:(NSString *)path;
//-(XADAction)unarchiver:(XADUnarchiver *)unarchiver creatingDirectoryDidFailForEntry:(int)n;

-(BOOL)extractionShouldStopForUnarchiver:(XADUnarchiver *)unarchiver;
-(void)unarchiver:(XADUnarchiver *)unarchiver extractionProgressForEntryWithDictionary:(NSDictionary *)dict
fileFraction:(double)fileprogress estimatedTotalFraction:(double)totalprogress;

@end


double _XADUnarchiverGetTime();
