#import <Foundation/Foundation.h>

#import "XADArchiveParser.h"

typedef NS_ENUM(int, XADForkStyle) {
	XADIgnoredForkStyle = 0,
	XADMacOSXForkStyle = 1,
	XADHiddenAppleDoubleForkStyle = 2,
	XADVisibleAppleDoubleForkStyle = 3,
	XADHFVExplorerAppleDoubleForkStyle = 4
};

#ifdef __APPLE__
#define XADDefaultForkStyle XADMacOSXForkStyle
#else
#define XADDefaultForkStyle XADVisibleAppleDoubleForkStyle
#endif

@protocol XADUnarchiverDelegate;

@interface XADUnarchiver:NSObject <XADArchiveParserDelegate>
{
	XADArchiveParser *parser;
	BOOL preservepermissions;

	BOOL shouldstop;

	NSMutableArray *deferreddirectories,*deferredlinks;
}

+(XADUnarchiver *)unarchiverForArchiveParser:(XADArchiveParser *)archiveparser;
+(XADUnarchiver *)unarchiverForPath:(NSString *)path;
+(XADUnarchiver *)unarchiverForPath:(NSString *)path error:(XADError *)errorptr;

-(instancetype)initWithArchiveParser:(XADArchiveParser *)archiveparser NS_DESIGNATED_INITIALIZER;
-(void)dealloc;

@property (NS_NONATOMIC_IOSONLY, readonly, strong) XADArchiveParser *archiveParser;

@property (NS_NONATOMIC_IOSONLY, assign) id<XADUnarchiverDelegate> delegate;

@property (NS_NONATOMIC_IOSONLY, copy) NSString *destination;

@property (NS_NONATOMIC_IOSONLY) XADForkStyle macResourceForkStyle;

@property (NS_NONATOMIC_IOSONLY, setter=setPreserevesPermissions:) BOOL preservesPermissions;

@property (NS_NONATOMIC_IOSONLY) double updateInterval;

@property (NS_NONATOMIC_IOSONLY, readonly) XADError parseAndUnarchive;

-(XADError)extractEntryWithDictionary:(NSDictionary *)dict;
-(XADError)extractEntryWithDictionary:(NSDictionary *)dict forceDirectories:(BOOL)force;
-(XADError)extractEntryWithDictionary:(NSDictionary *)dict as:(NSString *)path;
-(XADError)extractEntryWithDictionary:(NSDictionary *)dict as:(NSString *)path forceDirectories:(BOOL)force;

@property (NS_NONATOMIC_IOSONLY, readonly) XADError finishExtractions;
@property (NS_NONATOMIC_IOSONLY, readonly) XADError _fixDeferredLinks;
@property (NS_NONATOMIC_IOSONLY, readonly) XADError _fixDeferredDirectories;

-(XADUnarchiver *)unarchiverForEntryWithDictionary:(NSDictionary *)dict
wantChecksum:(BOOL)checksum error:(XADError *)errorptr;
-(XADUnarchiver *)unarchiverForEntryWithDictionary:(NSDictionary *)dict
resourceForkDictionary:(NSDictionary *)forkdict wantChecksum:(BOOL)checksum error:(XADError *)errorptr;

-(XADError)_extractFileEntryWithDictionary:(NSDictionary *)dict as:(NSString *)destpath;
-(XADError)_extractDirectoryEntryWithDictionary:(NSDictionary *)dict as:(NSString *)destpath;
-(XADError)_extractLinkEntryWithDictionary:(NSDictionary *)dict as:(NSString *)destpath;
-(XADError)_extractArchiveEntryWithDictionary:(NSDictionary *)dict to:(NSString *)destpath name:(NSString *)filename;
-(XADError)_extractResourceForkEntryWithDictionary:(NSDictionary *)dict asAppleDoubleFile:(NSString *)destpath;

-(XADError)_updateFileAttributesAtPath:(NSString *)path forEntryWithDictionary:(NSDictionary *)dict
deferDirectories:(BOOL)defer;
-(XADError)_ensureDirectoryExists:(NSString *)path;

-(XADError)runExtractorWithDictionary:(NSDictionary *)dict outputHandle:(CSHandle *)handle;
-(XADError)runExtractorWithDictionary:(NSDictionary *)dict
outputTarget:(id)target selector:(SEL)sel argument:(id)arg;

-(NSString *)adjustPathString:(NSString *)path forEntryWithDictionary:(NSDictionary *)dict;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL _shouldStop;

@end




@protocol XADUnarchiverDelegate <NSObject>

@optional
-(void)unarchiverNeedsPassword:(XADUnarchiver *)unarchiver;

-(BOOL)unarchiver:(XADUnarchiver *)unarchiver shouldExtractEntryWithDictionary:(NSDictionary *)dict suggestedPath:(NSString **)pathptr;
-(void)unarchiver:(XADUnarchiver *)unarchiver willExtractEntryWithDictionary:(NSDictionary *)dict to:(NSString *)path;
-(void)unarchiver:(XADUnarchiver *)unarchiver didExtractEntryWithDictionary:(NSDictionary *)dict to:(NSString *)path error:(XADError)error;

@required
-(BOOL)unarchiver:(XADUnarchiver *)unarchiver shouldCreateDirectory:(NSString *)directory;
@optional
-(BOOL)unarchiver:(XADUnarchiver *)unarchiver shouldDeleteFileAndCreateDirectory:(NSString *)directory;

@optional
-(BOOL)unarchiver:(XADUnarchiver *)unarchiver shouldExtractArchiveEntryWithDictionary:(NSDictionary *)dict to:(NSString *)path;
-(void)unarchiver:(XADUnarchiver *)unarchiver willExtractArchiveEntryWithDictionary:(NSDictionary *)dict withUnarchiver:(XADUnarchiver *)subunarchiver to:(NSString *)path;
-(void)unarchiver:(XADUnarchiver *)unarchiver didExtractArchiveEntryWithDictionary:(NSDictionary *)dict withUnarchiver:(XADUnarchiver *)subunarchiver to:(NSString *)path error:(XADError)error;

@required
-(NSString *)unarchiver:(XADUnarchiver *)unarchiver destinationForLink:(XADString *)link from:(NSString *)path;

-(BOOL)extractionShouldStopForUnarchiver:(XADUnarchiver *)unarchiver;
-(void)unarchiver:(XADUnarchiver *)unarchiver extractionProgressForEntryWithDictionary:(NSDictionary *)dict
fileFraction:(double)fileprogress estimatedTotalFraction:(double)totalprogress;

@optional
-(void)unarchiver:(XADUnarchiver *)unarchiver findsFileInterestingForReason:(NSString *)reason;

@optional
// Deprecated.
-(NSString *)unarchiver:(XADUnarchiver *)unarchiver pathForExtractingEntryWithDictionary:(NSDictionary *)dict DEPRECATED_ATTRIBUTE;
-(BOOL)unarchiver:(XADUnarchiver *)unarchiver shouldExtractEntryWithDictionary:(NSDictionary *)dict to:(NSString *)path DEPRECATED_ATTRIBUTE;
-(NSString *)unarchiver:(XADUnarchiver *)unarchiver linkDestinationForEntryWithDictionary:(NSDictionary *)dict from:(NSString *)path DEPRECATED_ATTRIBUTE;
@end
