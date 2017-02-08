#import "XADZipParser.h"

@interface XADZipSFXParser:XADZipParser
{
}

+(int)requiredHeaderSize;
+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data name:(NSString *)name;
-(NSString *)formatName;

@end

@interface XADWinZipSFXParser:XADZipParser
{
}

+(int)requiredHeaderSize;
+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data name:(NSString *)name;
-(NSString *)formatName;

@end

@interface XADZipItSEAParser:XADZipParser
{
}

+(int)requiredHeaderSize;
+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data name:(NSString *)name;
-(NSString *)formatName;

@end

@interface XADZipMultiPartParser:XADZipParser
{
}

+(int)requiredHeaderSize;
+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data name:(NSString *)name;
-(NSString *)formatName;

@end
