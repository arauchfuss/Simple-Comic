#import "XADString.h"

#define XADUnixPathSeparator "/"
#define XADWindowsPathSeparator "\\"
#define XADEitherPathSeparator "/\\"
#define XADNoPathSeparator ""

@interface XADPath:NSObject <XADString,NSCopying>
{
	XADPath *parent;

	NSArray *cachedcanonicalcomponents;
	NSString *cachedencoding;
}

+(XADPath *)emptyPath;
+(XADPath *)pathWithString:(NSString *)string;
+(XADPath *)pathWithStringComponents:(NSArray *)components;
+(XADPath *)separatedPathWithString:(NSString *)string;
+(XADPath *)decodedPathWithData:(NSData *)bytedata encodingName:(NSString *)encoding separators:(const char *)separators;
+(XADPath *)analyzedPathWithData:(NSData *)bytedata source:(XADStringSource *)stringsource
separators:(const char *)pathseparators;

-(instancetype)init NS_DESIGNATED_INITIALIZER;
-(instancetype)initWithParent:(XADPath *)parentpath NS_DESIGNATED_INITIALIZER;
-(instancetype)initWithPath:(XADPath *)path parent:(XADPath *)parentpath;

-(void)dealloc;

@property (NS_NONATOMIC_IOSONLY, getter=isAbsolute, readonly) BOOL absolute;
@property (NS_NONATOMIC_IOSONLY, getter=isEmpty, readonly) BOOL empty;
-(BOOL)isEqual:(id)other;
-(BOOL)isCanonicallyEqual:(id)other;
-(BOOL)isCanonicallyEqual:(id)other encodingName:(NSString *)encoding;
-(BOOL)hasPrefix:(XADPath *)other;
-(BOOL)hasCanonicalPrefix:(XADPath *)other;
-(BOOL)hasCanonicalPrefix:(XADPath *)other encodingName:(NSString *)encoding;

@property (NS_NONATOMIC_IOSONLY, readonly) int depth; // Note: Does not take . or .. paths into account.
-(int)depthWithEncodingName:(NSString *)encoding;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *pathComponents;
-(NSArray *)pathComponentsWithEncodingName:(NSString *)encoding;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *canonicalPathComponents;
-(NSArray *)canonicalPathComponentsWithEncodingName:(NSString *)encoding;
-(void)_addPathComponentsToArray:(NSMutableArray *)components encodingName:(NSString *)encoding;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *lastPathComponent;
-(NSString *)lastPathComponentWithEncodingName:(NSString *)encoding;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *firstPathComponent;
-(NSString *)firstPathComponentWithEncodingName:(NSString *)encoding;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *firstCanonicalPathComponent;
-(NSString *)firstCanonicalPathComponentWithEncodingName:(NSString *)encoding;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) XADPath *pathByDeletingLastPathComponent;
-(XADPath *)pathByDeletingLastPathComponentWithEncodingName:(NSString *)encoding;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) XADPath *pathByDeletingFirstPathComponent;
-(XADPath *)pathByDeletingFirstPathComponentWithEncodingName:(NSString *)encoding;

-(XADPath *)pathByAppendingXADStringComponent:(XADString *)component;
-(XADPath *)pathByAppendingPath:(XADPath *)path;
-(XADPath *)_copyWithParent:(XADPath *)newparent;

// These are safe for filesystem use, and adapted to the current platform.
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *sanitizedPathString;
-(NSString *)sanitizedPathStringWithEncodingName:(NSString *)encoding;

// XADString interface.
// NOTE: These are not guaranteed to be safe for usage as filesystem paths,
// only for display!
-(BOOL)canDecodeWithEncodingName:(NSString *)encoding;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *string;
-(NSString *)stringWithEncodingName:(NSString *)encoding;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSData *data;
-(void)_appendPathToData:(NSMutableData *)data;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL encodingIsKnown;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *encodingName;
@property (NS_NONATOMIC_IOSONLY, readonly) float confidence;

@property (NS_NONATOMIC_IOSONLY, readonly, strong) XADStringSource *source;

#ifdef __APPLE__
-(BOOL)canDecodeWithEncoding:(NSStringEncoding)encoding;
-(NSString *)stringWithEncoding:(NSStringEncoding)encoding;
-(NSString *)sanitizedPathStringWithEncoding:(NSStringEncoding)encoding;
@property (NS_NONATOMIC_IOSONLY, readonly) NSStringEncoding encoding;
#endif

// Other interfaces.
@property (NS_NONATOMIC_IOSONLY, readonly) NSUInteger hash;
-(id)copyWithZone:(NSZone *)zone;

// Deprecated.
@property (NS_NONATOMIC_IOSONLY, readonly, copy) XADPath *safePath; // Deprecated. Use sanitizedPathString: instead.

// Subclass methods.
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL _isPartAbsolute;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL _isPartEmpty;
-(int)_depthOfPartWithEncodingName:(NSString *)encoding;
-(void)_addPathComponentsOfPartToArray:(NSMutableArray *)array encodingName:(NSString *)encoding;
-(NSString *)_lastPathComponentOfPartWithEncodingName:(NSString *)encoding;
-(NSString *)_firstPathComponentOfPartWithEncodingName:(NSString *)encoding;
-(XADPath *)_pathByDeletingLastPathComponentOfPartWithEncodingName:(NSString *)encoding;
-(XADPath *)_pathByDeletingFirstPathComponentOfPartWithEncodingName:(NSString *)encoding;
-(BOOL)_canDecodePartWithEncodingName:(NSString *)encoding;
-(void)_appendPathForPartToData:(NSMutableData *)data;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) XADStringSource *_sourceForPart;

@end


@interface XADStringPath:XADPath
{
	NSString *string;
}

-(instancetype)initWithComponentString:(NSString *)pathstring NS_DESIGNATED_INITIALIZER;
-(instancetype)initWithComponentString:(NSString *)pathstring parent:(XADPath *)parentpath NS_DESIGNATED_INITIALIZER;
-(instancetype)initWithPath:(XADStringPath *)path parent:(XADPath *)parentpath;
-(void)dealloc;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL _isPartAbsolute;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL _isPartEmpty;
-(int)_depthOfPartWithEncodingName:(NSString *)encoding;
-(void)_addPathComponentsOfPartToArray:(NSMutableArray *)array encodingName:(NSString *)encoding;
-(NSString *)_lastPathComponentOfPartWithEncodingName:(NSString *)encoding;
-(NSString *)_firstPathComponentOfPartWithEncodingName:(NSString *)encoding;
-(XADPath *)_pathByDeletingLastPathComponentOfPartWithEncodingName:(NSString *)encoding;
-(XADPath *)_pathByDeletingFirstPathComponentOfPartWithEncodingName:(NSString *)encoding;
-(BOOL)_canDecodePartWithEncodingName:(NSString *)encoding;
-(void)_appendPathForPartToData:(NSMutableData *)data;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) XADStringSource *_sourceForPart;

-(BOOL)isEqual:(id)other;
@property (NS_NONATOMIC_IOSONLY, readonly) NSUInteger hash;

@end

@interface XADRawPath:XADPath
{
	NSData *data;
	XADStringSource *source;
	const char *separators;
}

-(instancetype)initWithData:(NSData *)bytedata source:(XADStringSource *)stringsource
separators:(const char *)pathseparators NS_DESIGNATED_INITIALIZER;
-(instancetype)initWithData:(NSData *)bytedata source:(XADStringSource *)stringsource
separators:(const char *)pathseparators parent:(XADPath *)parentpath NS_DESIGNATED_INITIALIZER;
-(instancetype)initWithPath:(XADRawPath *)path parent:(XADPath *)parentpath;
-(void)dealloc;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL _isPartAbsolute;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL _isPartEmpty;
-(int)_depthOfPartWithEncodingName:(NSString *)encoding;
-(void)_addPathComponentsOfPartToArray:(NSMutableArray *)array encodingName:(NSString *)encoding;
-(NSString *)_lastPathComponentOfPartWithEncodingName:(NSString *)encoding;
-(NSString *)_firstPathComponentOfPartWithEncodingName:(NSString *)encoding;
-(XADPath *)_pathByDeletingLastPathComponentOfPartWithEncodingName:(NSString *)encoding;
-(XADPath *)_pathByDeletingFirstPathComponentOfPartWithEncodingName:(NSString *)encoding;
-(BOOL)_canDecodePartWithEncodingName:(NSString *)encoding;
-(void)_appendPathForPartToData:(NSMutableData *)data;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) XADStringSource *_sourceForPart;

@end

