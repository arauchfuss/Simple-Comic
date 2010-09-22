#import <Foundation/Foundation.h>

@class XADStringSource,UniversalDetector;


extern NSString *XADUTF8StringEncodingName;


@protocol XADString <NSObject>

-(NSString *)string;
-(NSString *)stringWithEncodingName:(NSString *)encoding;
-(NSData *)data;

-(BOOL)encodingIsKnown;
-(NSString *)encodingName;
-(float)confidence;

-(XADStringSource *)source;

#ifdef __APPLE__
-(NSString *)stringWithEncoding:(NSStringEncoding)encoding;
-(NSStringEncoding)encoding;
#endif

@end



@interface XADString:NSObject <XADString>
{
	NSData *data;
	NSString *string;
	XADStringSource *source;
}

+(XADString *)XADStringWithString:(NSString *)knownstring;

-(id)initWithData:(NSData *)bytedata source:(XADStringSource *)stringsource;
-(id)initWithData:(NSData *)bytedata encodingName:(NSString *)encoding;
-(id)initWithString:(NSString *)knownstring;
-(void)dealloc;

-(NSString *)string;
-(NSString *)stringWithEncodingName:(NSString *)encoding;
-(NSData *)data;

-(BOOL)encodingIsKnown;
-(NSString *)encodingName;
-(float)confidence;

-(XADStringSource *)source;

-(BOOL)hasASCIIPrefix:(NSString *)asciiprefix;
-(XADString *)XADStringByStrippingASCIIPrefixOfLength:(int)length;

-(BOOL)isEqual:(id)other;
-(NSUInteger)hash;

-(NSString *)description;
-(id)copyWithZone:(NSZone *)zone;

#ifdef __APPLE__
-(NSString *)stringWithEncoding:(NSStringEncoding)encoding;
-(NSStringEncoding)encoding;
#endif

@end

@interface XADString (PlatformSpecific)

+(NSString *)stringForData:(NSData *)data encodingName:(NSString *)encoding;
+(NSData *)dataForString:(NSString *)string encodingName:(NSString *)encoding;
+(NSArray *)availableEncodingNames;

@end




@interface XADStringSource:NSObject
{
	UniversalDetector *detector;
	NSString *fixedencodingname;
	BOOL mac;

	#ifdef __APPLE__
	NSStringEncoding fixedencoding;
	#endif
}

-(id)init;
-(void)dealloc;

-(BOOL)analyzeDataAndCheckForASCII:(NSData *)data;

-(NSString *)encodingName;
-(float)confidence;
-(UniversalDetector *)detector;

-(void)setFixedEncodingName:(NSString *)encodingname;
-(BOOL)hasFixedEncoding;
-(void)setPrefersMacEncodings:(BOOL)prefermac;

#ifdef __APPLE__
-(NSStringEncoding)encoding;
-(void)setFixedEncoding:(NSStringEncoding)encoding;
#endif

@end
