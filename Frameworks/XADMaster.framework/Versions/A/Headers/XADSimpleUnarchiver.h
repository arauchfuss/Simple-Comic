#import <Foundation/Foundation.h>

#import "XADArchiveParser.h"
#import "XADUnarchiver.h"
#import "XADRegex.h"

#define XADNeverCreateEnclosingDirectory 0
#define XADAlwaysCreateEnclosingDirectory 1
#define XADCreateEnclosingDirectoryWhenNeeded 2

@protocol XADSimpleUnarchiverDelegate;

@interface XADSimpleUnarchiver:NSObject<XADArchiveParserDelegate, XADUnarchiverDelegate>
{
	XADArchiveParser *parser;
	XADUnarchiver *unarchiver,*subunarchiver;

	BOOL shouldstop;

	NSString *destination,*enclosingdir;
	BOOL extractsubarchives,removesolo;
	BOOL overwrite,rename,skip;
	BOOL copydatetoenclosing,copydatetosolo,resetsolodate;
	BOOL propagatemetadata;

	NSMutableArray *regexes;
	NSMutableIndexSet *indices;

	NSMutableArray *entries,*reasonsforinterest;
	NSMutableDictionary *renames;
	NSMutableSet *resourceforks;
	id metadata;
	NSString *unpackdestination,*finaldestination,*overridesoloitem;
	int numextracted;

	NSString *toplevelname;
	BOOL lookslikesolo;

	off_t totalsize,currsize,totalprogress;
}

+(XADSimpleUnarchiver *)simpleUnarchiverForPath:(NSString *)path;
+(XADSimpleUnarchiver *)simpleUnarchiverForPath:(NSString *)path error:(XADError *)errorptr;

-(instancetype)initWithArchiveParser:(XADArchiveParser *)archiveparser;
-(instancetype)initWithArchiveParser:(XADArchiveParser *)archiveparser entries:(NSArray *)entryarray NS_DESIGNATED_INITIALIZER;
-(void)dealloc;

@property (NS_NONATOMIC_IOSONLY, readonly, strong) XADArchiveParser *archiveParser;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) XADArchiveParser *outerArchiveParser;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) XADArchiveParser *innerArchiveParser;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *reasonsForInterest;

@property (NS_NONATOMIC_IOSONLY, assign) id<XADSimpleUnarchiverDelegate> delegate;

// TODO: Encoding wrappers?

@property (NS_NONATOMIC_IOSONLY, copy) NSString *password;

@property (NS_NONATOMIC_IOSONLY, copy) NSString *destination;

@property (NS_NONATOMIC_IOSONLY, copy) NSString *enclosingDirectoryName;

@property (NS_NONATOMIC_IOSONLY) BOOL removesEnclosingDirectoryForSoloItems;

@property (NS_NONATOMIC_IOSONLY) BOOL alwaysOverwritesFiles;

@property (NS_NONATOMIC_IOSONLY) BOOL alwaysRenamesFiles;

@property (NS_NONATOMIC_IOSONLY) BOOL alwaysSkipsFiles;

@property (NS_NONATOMIC_IOSONLY) BOOL extractsSubArchives;

@property (NS_NONATOMIC_IOSONLY) BOOL copiesArchiveModificationTimeToEnclosingDirectory;

@property (NS_NONATOMIC_IOSONLY) BOOL copiesArchiveModificationTimeToSoloItems;

@property (NS_NONATOMIC_IOSONLY) BOOL resetsDateForSoloItems;

@property (NS_NONATOMIC_IOSONLY) BOOL propagatesRelevantMetadata;

@property (NS_NONATOMIC_IOSONLY) int macResourceForkStyle;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL preservesPermissions;
-(void)setPreserevesPermissions:(BOOL)preserveflag;

@property (NS_NONATOMIC_IOSONLY) double updateInterval;

-(void)addGlobFilter:(NSString *)wildcard;
-(void)addRegexFilter:(XADRegex *)regex;
-(void)addIndexFilter:(int)index;
-(void)setIndices:(NSIndexSet *)indices;

@property (NS_NONATOMIC_IOSONLY, readonly) off_t predictedTotalSize;
-(off_t)predictedTotalSizeIgnoringUnknownFiles:(BOOL)ignoreunknown;

@property (NS_NONATOMIC_IOSONLY, readonly) int numberOfItemsExtracted;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL wasSoloItem;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *actualDestination;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *soloItem;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *createdItem;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *createdItemOrActualDestination;



@property (NS_NONATOMIC_IOSONLY, readonly) XADError parse;
-(XADError)_setupSubArchiveForEntryWithDataFork:(NSDictionary *)datadict resourceFork:(NSDictionary *)resourcedict;

@property (NS_NONATOMIC_IOSONLY, readonly) XADError unarchive;
@property (NS_NONATOMIC_IOSONLY, readonly) XADError _unarchiveRegularArchive;
@property (NS_NONATOMIC_IOSONLY, readonly) XADError _unarchiveSubArchive;

@property (NS_NONATOMIC_IOSONLY, readonly) XADError _finalizeExtraction;

-(void)_testForSoloItems:(NSDictionary *)entry;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL _shouldStop;

-(NSString *)_checkPath:(NSString *)path forEntryWithDictionary:(NSDictionary *)dict deferred:(BOOL)deferred;
-(BOOL)_recursivelyMoveItemAtPath:(NSString *)src toPath:(NSString *)dest overwrite:(BOOL)overwritethislevel;

+(NSString *)_findUniquePathForOriginalPath:(NSString *)path;
+(NSString *)_findUniquePathForOriginalPath:(NSString *)path reservedPaths:(NSSet *)reserved;

@end



@protocol XADSimpleUnarchiverDelegate <NSObject>

-(void)simpleUnarchiverNeedsPassword:(XADSimpleUnarchiver *)unarchiver;

-(NSString *)simpleUnarchiver:(XADSimpleUnarchiver *)unarchiver encodingNameForXADString:(id <XADString>)string;

-(BOOL)simpleUnarchiver:(XADSimpleUnarchiver *)unarchiver shouldExtractEntryWithDictionary:(NSDictionary *)dict to:(NSString *)path;
-(void)simpleUnarchiver:(XADSimpleUnarchiver *)unarchiver willExtractEntryWithDictionary:(NSDictionary *)dict to:(NSString *)path;
-(void)simpleUnarchiver:(XADSimpleUnarchiver *)unarchiver didExtractEntryWithDictionary:(NSDictionary *)dict to:(NSString *)path error:(XADError)error;

-(NSString *)simpleUnarchiver:(XADSimpleUnarchiver *)unarchiver replacementPathForEntryWithDictionary:(NSDictionary *)dict
originalPath:(NSString *)path suggestedPath:(NSString *)unique;
-(NSString *)simpleUnarchiver:(XADSimpleUnarchiver *)unarchiver deferredReplacementPathForOriginalPath:(NSString *)path
suggestedPath:(NSString *)unique;

-(BOOL)extractionShouldStopForSimpleUnarchiver:(XADSimpleUnarchiver *)unarchiver;

-(void)simpleUnarchiver:(XADSimpleUnarchiver *)unarchiver
extractionProgressForEntryWithDictionary:(NSDictionary *)dict
fileProgress:(off_t)fileprogress of:(off_t)filesize
totalProgress:(off_t)totalprogress of:(off_t)totalsize;
-(void)simpleUnarchiver:(XADSimpleUnarchiver *)unarchiver
estimatedExtractionProgressForEntryWithDictionary:(NSDictionary *)dict
fileProgress:(double)fileprogress totalProgress:(double)totalprogress;

@end
