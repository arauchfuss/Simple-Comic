#import "XADMacArchiveParser.h"

@interface XADLZHParser:XADMacArchiveParser
{
}

+(int)requiredHeaderSize;
+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data name:(NSString *)name;

-(void)parseWithSeparateMacForks;
-(void)parseExtendedForDictionary:(NSMutableDictionary *)dict size:(int)size;

-(CSHandle *)rawHandleForEntryWithDictionary:(NSDictionary *)dict wantChecksum:(BOOL)checksum;
-(NSString *)formatName;

@end
