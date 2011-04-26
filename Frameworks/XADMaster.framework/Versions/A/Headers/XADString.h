#import <Foundation/Foundation.h>

@class XADStringSource,UniversalDetector;


extern NSString *XADUTF8StringEncodingName;
extern NSString *XADASCIIStringEncodingName;

extern NSString *XADISOLatin1StringEncodingName;
extern NSString *XADISOLatin2StringEncodingName;
extern NSString *XADISOLatin3StringEncodingName;
extern NSString *XADISOLatin4StringEncodingName;
extern NSString *XADISOLatin5StringEncodingName;
extern NSString *XADISOLatin6StringEncodingName;
extern NSString *XADISOLatin7StringEncodingName;
extern NSString *XADISOLatin8StringEncodingName;
extern NSString *XADISOLatin9StringEncodingName;
extern NSString *XADISOLatin10StringEncodingName;
extern NSString *XADISOLatin11StringEncodingName;
extern NSString *XADISOLatin12StringEncodingName;
extern NSString *XADISOLatin13StringEncodingName;
extern NSString *XADISOLatin14StringEncodingName;
extern NSString *XADISOLatin15StringEncodingName;
extern NSString *XADISOLatin16StringEncodingName;

extern NSString *XADShiftJISStringEncodingName;

extern NSString *XADWindowsCP1250StringEncodingName;
extern NSString *XADWindowsCP1251StringEncodingName;
extern NSString *XADWindowsCP1252StringEncodingName;
extern NSString *XADWindowsCP1253StringEncodingName;
extern NSString *XADWindowsCP1254StringEncodingName;

extern NSString *XADMacOSRomanStringEncodingName;
extern NSString *XADMacOSJapaneseStringEncodingName;
extern NSString *XADMacOSTraditionalChineseStringEncodingName;
extern NSString *XADMacOSKoreanStringEncodingName;
extern NSString *XADMacOSArabicStringEncodingName;
extern NSString *XADMacOSHebrewStringEncodingName;
extern NSString *XADMacOSGreekStringEncodingName;
extern NSString *XADMacOSCyrillicStringEncodingName;
extern NSString *XADMacOSSimplifiedChineseStringEncodingName;
extern NSString *XADMacOSRomanianStringEncodingName;
extern NSString *XADMacOSUkranianStringEncodingName;
extern NSString *XADMacOSThaiStringEncodingName;
extern NSString *XADMacOSCentralEuropeanRomanStringEncodingName;
extern NSString *XADMacOSIcelandicStringEncodingName;
extern NSString *XADMacOSTurkishStringEncodingName;
extern NSString *XADMacOSCroatianStringEncodingName;


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
