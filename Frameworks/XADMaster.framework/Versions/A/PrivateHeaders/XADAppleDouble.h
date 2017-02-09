#import "CSHandle.h"

@interface XADAppleDouble:NSObject
{
}

+(BOOL)parseAppleDoubleWithHandle:(CSHandle *)fh resourceForkOffset:(off_t *)resourceoffsetptr
resourceForkLength:(off_t *)resourcelengthptr extendedAttributes:(NSDictionary **)extattrsptr;
+(void)parseAppleDoubleExtendedAttributesWithHandle:(CSHandle *)fh intoDictionary:(NSMutableDictionary *)extattrs;

+(void)writeAppleDoubleHeaderToHandle:(CSHandle *)fh resourceForkSize:(int)ressize
extendedAttributes:(NSDictionary *)extattrs;

@end

