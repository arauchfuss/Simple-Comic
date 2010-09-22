#import "XADString.h"

#define XADUnixPathSeparator "/"
#define XADWindowsPathSeparator "\\"
#define XADEitherPathSeparator "/\\"
#define XADNoPathSeparator ""

@interface XADPath:NSObject <XADString>
{
	NSArray *components;
	XADStringSource *source;
}

-(id)init;
-(id)initWithComponents:(NSArray *)pathcomponents;
-(id)initWithString:(NSString *)pathstring;
-(id)initWithBytes:(const char *)bytes length:(int)length
encodingName:(NSString *)encoding separators:(const char *)separators;
-(id)initWithBytes:(const char *)bytes length:(int)length
separators:(const char *)separators source:(XADStringSource *)stringsource;
-(id)initWithBytes:(const char *)bytes length:(int)length encodingName:(NSString *)encoding
separators:(const char *)separators source:(XADStringSource *)stringsource;

-(void)dealloc;

-(XADString *)lastPathComponent;
-(XADString *)firstPathComponent;

-(XADPath *)pathByDeletingLastPathComponent;
-(XADPath *)pathByDeletingFirstPathComponent;
-(XADPath *)pathByAppendingPathComponent:(XADString *)component;
-(XADPath *)pathByAppendingPath:(XADPath *)path;
-(XADPath *)safePath;

-(BOOL)isAbsolute;
-(BOOL)hasPrefix:(XADPath *)other;

-(NSString *)string;
-(NSString *)stringWithEncodingName:(NSString *)encoding;
-(NSData *)data; // NOTE: not guaranteed to be safe for usage as a filesystem path, only for display!
-(int)depth;

-(BOOL)encodingIsKnown;
-(NSString *)encodingName;
-(float)confidence;

-(XADStringSource *)source;

-(BOOL)isEqual:(id)other;
-(NSUInteger)hash;
-(id)copyWithZone:(NSZone *)zone;

#ifdef __APPLE__
-(NSString *)stringWithEncoding:(NSStringEncoding)encoding;
-(NSStringEncoding)encoding;
#endif

@end
